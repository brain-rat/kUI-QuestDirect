// ForeverSync downloads WoW Forever data from the ForeverDB API (https://foreverdb.net)
// into a local folder, so it can be turned into data for QuestDirect and KUI. It needs your own ForeverDB API key. Data from ForeverDB.net.
//
// Usage: double-click, or
//
//	ForeverSync.exe [-key fdb_...] [-only quests,gathering,...] [-zone Durotar] [-refresh] [-out folder]
//
// It keeps to ForeverDB's limits (60 requests a minute, 10,000 a day) and picks up
// where it left off if it's stopped or hits the daily limit.
package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const (
	baseURL   = "https://foreverdb.net/api/v1"
	userAgent = "ForeverSync/1.0 (personal addon data tool)"
	pageSize  = 100
)

var (
	errDaily = errors.New("daily limit reached")
	errAuth  = errors.New("key refused")
)

type client struct {
	key      string
	http     *http.Client
	interval time.Duration
	last     time.Time
	requests int
	base     string
}

// get fetches one URL and returns the raw JSON body.
func (c *client) get(path string, q url.Values) ([]byte, error) {
	u := c.base + path
	if len(q) > 0 {
		u += "?" + q.Encode()
	}
	for attempt := 0; ; attempt++ {
		if wait := c.interval - time.Since(c.last); wait > 0 {
			time.Sleep(wait)
		}
		c.last = time.Now()
		req, _ := http.NewRequest("GET", u, nil)
		req.Header.Set("X-API-Key", c.key)
		req.Header.Set("Accept", "application/json")
		req.Header.Set("User-Agent", userAgent)
		resp, err := c.http.Do(req)
		if err != nil {
			if attempt < 4 {
				time.Sleep(time.Duration(attempt+1) * 5 * time.Second)
				continue
			}
			return nil, err
		}
		body, _ := io.ReadAll(resp.Body)
		resp.Body.Close()
		c.requests++
		switch {
		case resp.StatusCode == 200:
			return body, nil
		case resp.StatusCode == 401 || resp.StatusCode == 403:
			return nil, fmt.Errorf("%w (%d): %s", errAuth, resp.StatusCode, short(body))
		case resp.StatusCode == 404:
			return nil, nil
		case resp.StatusCode == 429:
			if strings.Contains(strings.ToLower(string(body)+resp.Header.Get("X-Daily")), "daily") ||
				dailyLeft(resp.Header.Get("X-Daily")) == 0 {
				return nil, errDaily
			}
			secs, err := strconv.Atoi(resp.Header.Get("Retry-After"))
			if err != nil || secs < 0 {
				secs = 60
			}
			fmt.Printf("  slowing down for %d s (ForeverDB's per-minute limit)\n", secs)
			time.Sleep(time.Duration(secs+1) * time.Second)
		case resp.StatusCode >= 500 && attempt < 4:
			time.Sleep(time.Duration(attempt+1) * 10 * time.Second)
		default:
			return nil, fmt.Errorf("HTTP %d for %s: %s", resp.StatusCode, path, short(body))
		}
	}
}

// dailyLeft reads "remaining" out of an X-Daily header like "9876/10000" or "remaining=9876"; -1 if unknown.
func dailyLeft(h string) int {
	if h == "" {
		return -1
	}
	if i := strings.Index(h, "remaining="); i >= 0 {
		n, err := strconv.Atoi(strings.TrimFunc(h[i+10:], func(r rune) bool { return r < '0' || r > '9' }))
		if err == nil {
			return n
		}
	}
	if parts := strings.Split(h, "/"); len(parts) == 2 {
		used, e1 := strconv.Atoi(strings.TrimSpace(parts[0]))
		limit, e2 := strconv.Atoi(strings.TrimSpace(parts[1]))
		if e1 == nil && e2 == nil {
			return limit - used
		}
	}
	return -1
}

func short(b []byte) string {
	s := strings.TrimSpace(string(b))
	if len(s) > 200 {
		s = s[:200] + "..."
	}
	return s
}

// envelope is ForeverDB's { data, meta } answer.
type envelope struct {
	Data json.RawMessage        `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// list pages through a list endpoint and returns every item.
func (c *client) list(path string, q url.Values, label string) ([]json.RawMessage, map[string]interface{}, error) {
	var all []json.RawMessage
	var meta map[string]interface{}
	for offset := 0; ; offset += pageSize {
		qq := url.Values{}
		for k, v := range q {
			qq[k] = v
		}
		qq.Set("limit", strconv.Itoa(pageSize))
		qq.Set("offset", strconv.Itoa(offset))
		body, err := c.get(path, qq)
		if err != nil {
			return all, meta, err
		}
		if body == nil {
			break
		}
		var env envelope
		if err := json.Unmarshal(body, &env); err != nil {
			return all, meta, fmt.Errorf("%s: unexpected answer: %v", path, err)
		}
		meta = env.Meta
		var page []json.RawMessage
		if err := json.Unmarshal(env.Data, &page); err != nil {
			// not a list: keep the whole answer as one item
			all = append(all, env.Data)
			break
		}
		all = append(all, page...)
		total := metaInt(meta, "total", "count", "totalCount")
		if total > 0 {
			fmt.Printf("  %s: %d of %d\n", label, len(all), total)
		} else {
			fmt.Printf("  %s: %d\n", label, len(all))
		}
		if len(page) < pageSize || (total > 0 && len(all) >= total) {
			break
		}
	}
	return all, meta, nil
}

func metaInt(m map[string]interface{}, keys ...string) int {
	for _, k := range keys {
		if v, ok := m[k]; ok {
			switch t := v.(type) {
			case float64:
				return int(t)
			case string:
				n, _ := strconv.Atoi(t)
				return n
			}
		}
	}
	return 0
}

// idOf finds a record's id: "id", "questId", "vendorId" or "npcId".
func idOf(raw json.RawMessage) string {
	var m map[string]interface{}
	if json.Unmarshal(raw, &m) != nil {
		return ""
	}
	for _, k := range []string{"id", "questId", "vendorId", "npcId"} {
		switch t := m[k].(type) {
		case float64:
			return strconv.Itoa(int(t))
		case string:
			if t != "" {
				return t
			}
		}
	}
	return ""
}

func writeJSON(path string, v interface{}) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	b, err := json.MarshalIndent(v, "", " ")
	if err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0o644); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

func exists(p string) bool { _, err := os.Stat(p); return err == nil }

// details fetches /<kind>/<id> for every id not already saved.
func (c *client) details(kind string, ids []string, dir string, refresh bool) (int, error) {
	todo := []string{}
	for _, id := range ids {
		if id != "" && (refresh || !exists(filepath.Join(dir, id+".json"))) {
			todo = append(todo, id)
		}
	}
	if len(todo) == 0 {
		fmt.Printf("  %s: all %d already downloaded\n", kind, len(ids))
		return 0, nil
	}
	fmt.Printf("  %s: %d to download (about %d min at ForeverDB's pace)\n", kind, len(todo), (len(todo)+59)/60)
	start := time.Now()
	for i, id := range todo {
		body, err := c.get("/"+kind+"/"+url.PathEscape(id), nil)
		if err != nil {
			return i, err
		}
		if body != nil {
			var env envelope
			if json.Unmarshal(body, &env) == nil && len(env.Data) > 0 {
				var v interface{}
				_ = json.Unmarshal(env.Data, &v)
				if err := writeJSON(filepath.Join(dir, id+".json"), v); err != nil {
					return i, err
				}
			}
		}
		if (i+1)%50 == 0 || i+1 == len(todo) {
			left := time.Duration(float64(time.Since(start)) / float64(i+1) * float64(len(todo)-i-1))
			fmt.Printf("  %s: %d/%d, about %d min left\n", kind, i+1, len(todo), int(left.Minutes()+0.5))
		}
	}
	return len(todo), nil
}

func resolveKey(flagKey, dir string) (string, error) {
	if flagKey != "" {
		return strings.TrimSpace(flagKey), nil
	}
	if k := os.Getenv("FOREVERDB_KEY"); k != "" {
		return strings.TrimSpace(k), nil
	}
	keyFile := filepath.Join(dir, "key.txt")
	if b, err := os.ReadFile(keyFile); err == nil && strings.TrimSpace(string(b)) != "" {
		return strings.TrimSpace(string(b)), nil
	}
	fmt.Println("Paste your ForeverDB API key (it starts with fdb_) and press Enter.")
	fmt.Println("Get one at https://foreverdb.net/developers. It's saved in key.txt next to this program.")
	fmt.Print("> ")
	line, _ := bufio.NewReader(os.Stdin).ReadString('\n')
	key := strings.TrimSpace(line)
	if key == "" {
		return "", errors.New("no key given")
	}
	_ = os.WriteFile(keyFile, []byte(key+"\n"), 0o600)
	return key, nil
}

func pause(interactive bool) {
	if interactive {
		fmt.Print("\nPress Enter to close.")
		_, _ = bufio.NewReader(os.Stdin).ReadString('\n')
	}
}

func run() int {
	exe, _ := os.Executable()
	home := filepath.Dir(exe)
	keyFlag := flag.String("key", "", "ForeverDB API key (otherwise key.txt or FOREVERDB_KEY)")
	only := flag.String("only", "", "comma list: meta,zones,changes,quests,gathering,vendors (default: meta,zones,changes,quests)")
	zone := flag.String("zone", "", "limit quests and gathering to one zone (map ID or name)")
	refresh := flag.Bool("refresh", false, "download details again even if already saved")
	out := flag.String("out", filepath.Join(home, "data"), "where to save the data")
	base := flag.String("base", baseURL, "API address (for testing)")
	flag.Parse()
	interactive := len(os.Args) == 1

	fmt.Println("ForeverSync: WoW Forever data from ForeverDB.net")
	fmt.Println()
	key, err := resolveKey(*keyFlag, home)
	if err != nil {
		fmt.Println("Stopped:", err)
		pause(interactive)
		return 1
	}
	c := &client{key: key, http: &http.Client{Timeout: 60 * time.Second}, interval: 1050 * time.Millisecond, base: strings.TrimRight(*base, "/")}

	want := map[string]bool{}
	for _, s := range strings.Split(*only, ",") {
		if s = strings.TrimSpace(strings.ToLower(s)); s != "" {
			want[s] = true
		}
	}
	// The default set is what QuestDirect and kUI use; gathering and vendors are opt-in.
	if len(want) == 0 {
		for _, s := range []string{"meta", "zones", "changes", "quests"} {
			want[s] = true
		}
	}
	do := func(s string) bool { return want[s] }
	manifest := map[string]interface{}{"source": "Data from ForeverDB.net (https://foreverdb.net)", "started": time.Now().UTC().Format(time.RFC3339)}
	counts := map[string]int{}

	stop := func(err error) int {
		switch {
		case errors.Is(err, errDaily):
			fmt.Println("\nForeverDB's daily limit is used up. Run ForeverSync again tomorrow and it carries on from here.")
		case errors.Is(err, errAuth):
			fmt.Println("\nForeverDB refused the key:", err)
			fmt.Println("Check it at https://foreverdb.net/developers. To enter a new one, delete key.txt and run again.")
		default:
			fmt.Println("\nStopped:", err)
		}
		manifest["stopped"] = err.Error()
		manifest["counts"] = counts
		manifest["requests"] = c.requests
		_ = writeJSON(filepath.Join(*out, "manifest.json"), manifest)
		pause(interactive)
		return 2
	}

	if do("meta") {
		fmt.Println("Game build and totals")
		body, err := c.get("/meta", nil)
		if err != nil {
			return stop(err)
		}
		var env envelope
		if json.Unmarshal(body, &env) == nil {
			_ = writeJSON(filepath.Join(*out, "meta.json"), env)
			manifest["meta"] = env.Meta
		}
	}
	if do("zones") {
		fmt.Println("Zones")
		zones, _, err := c.list("/zones", nil, "zones")
		if err != nil {
			return stop(err)
		}
		_ = writeJSON(filepath.Join(*out, "zones.json"), zones)
		counts["zones"] = len(zones)
	}
	if do("gathering") {
		fmt.Println("Gathering spawns")
		for _, slug := range []string{"herbalism", "mining", "skinning", "fishing"} {
			q := url.Values{}
			if *zone != "" {
				q.Set("zone", *zone)
			}
			body, err := c.get("/gathering/"+slug, q)
			if err != nil {
				return stop(err)
			}
			if body != nil {
				var env envelope
				if json.Unmarshal(body, &env) == nil {
					var v interface{}
					_ = json.Unmarshal(env.Data, &v)
					_ = writeJSON(filepath.Join(*out, "gathering", slug+".json"), v)
					counts["gathering_"+slug] = 1
				}
			}
			fmt.Println("  " + slug)
		}
	}
	if do("changes") {
		fmt.Println("Changes players have seen in Forever")
		for _, kind := range []string{"quest", "npc", "item", "vendor", "trainer"} {
			rows, _, err := c.list("/changes-seen", url.Values{"kind": {kind}}, "changes ("+kind+")")
			if err != nil {
				return stop(err)
			}
			_ = writeJSON(filepath.Join(*out, "changes", kind+".json"), rows)
			counts["changes_"+kind] = len(rows)
		}
	}
	if do("quests") {
		fmt.Println("Quests")
		q := url.Values{}
		if *zone != "" {
			q.Set("zone", *zone)
		}
		rows, meta, err := c.list("/quests", q, "quest list")
		if err != nil {
			return stop(err)
		}
		_ = writeJSON(filepath.Join(*out, "quests_list.json"), map[string]interface{}{"meta": meta, "data": rows})
		ids := make([]string, 0, len(rows))
		for _, r := range rows {
			ids = append(ids, idOf(r))
		}
		counts["quests"] = len(ids)
		n, err := c.details("quests", ids, filepath.Join(*out, "quests"), *refresh)
		counts["quest_details_new"] = n
		if err != nil {
			return stop(err)
		}
	}
	if do("vendors") {
		fmt.Println("Vendors")
		rows, meta, err := c.list("/vendors", nil, "vendor list")
		if err != nil {
			return stop(err)
		}
		_ = writeJSON(filepath.Join(*out, "vendors_list.json"), map[string]interface{}{"meta": meta, "data": rows})
		ids := make([]string, 0, len(rows))
		for _, r := range rows {
			ids = append(ids, idOf(r))
		}
		counts["vendors"] = len(ids)
		n, err := c.details("vendors", ids, filepath.Join(*out, "vendors"), *refresh)
		counts["vendor_details_new"] = n
		if err != nil {
			return stop(err)
		}
	}

	manifest["finished"] = time.Now().UTC().Format(time.RFC3339)
	manifest["counts"] = counts
	manifest["requests"] = c.requests
	_ = writeJSON(filepath.Join(*out, "manifest.json"), manifest)
	fmt.Printf("\nDone: %d requests. Data is in %s\n", c.requests, *out)
	fmt.Println("Next: turn this into add-on data files.")
	pause(interactive)
	return 0
}

func main() { os.Exit(run()) }
