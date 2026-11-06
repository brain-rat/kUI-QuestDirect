package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func mock(t *testing.T, hits *int32, limited *int32) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		atomic.AddInt32(hits, 1)
		if r.Header.Get("X-API-Key") != "fdb_good" {
			w.WriteHeader(401)
			fmt.Fprint(w, `{"error":"invalid key"}`)
			return
		}
		if r.Header.Get("User-Agent") == "" || strings.Contains(r.Header.Get("User-Agent"), "@") {
			t.Errorf("user agent: %q", r.Header.Get("User-Agent"))
		}
		if atomic.LoadInt32(limited) > 0 {
			atomic.AddInt32(limited, -1)
			w.Header().Set("Retry-After", "0")
			w.WriteHeader(429)
			fmt.Fprint(w, `{"error":"slow down"}`)
			return
		}
		p := r.URL.Path
		switch {
		case p == "/quests":
			off, _ := strconv.Atoi(r.URL.Query().Get("offset"))
			lim, _ := strconv.Atoi(r.URL.Query().Get("limit"))
			var data []map[string]interface{}
			for i := off; i < off+lim && i < 230; i++ {
				data = append(data, map[string]interface{}{"id": 1000 + i, "name": fmt.Sprintf("Q%d", i)})
			}
			json.NewEncoder(w).Encode(map[string]interface{}{"data": data, "meta": map[string]interface{}{"total": 230, "build": "1.60.1"}})
		case strings.HasPrefix(p, "/quests/"):
			id := strings.TrimPrefix(p, "/quests/")
			if id == "1005" {
				w.WriteHeader(404)
				return
			}
			json.NewEncoder(w).Encode(map[string]interface{}{"data": map[string]interface{}{"id": id, "starts": []interface{}{map[string]interface{}{"type": "npc", "id": 3143}}}, "meta": map[string]interface{}{}})
		case p == "/daily":
			w.Header().Set("X-Daily", "10000/10000")
			w.WriteHeader(429)
		default:
			w.WriteHeader(404)
		}
	}))
}

func TestListDetailsAndLimits(t *testing.T) {
	var hits, limited int32
	srv := mock(t, &hits, &limited)
	defer srv.Close()
	c := &client{key: "fdb_good", http: srv.Client(), interval: time.Millisecond, base: srv.URL}

	rows, meta, err := c.list("/quests", nil, "q")
	if err != nil || len(rows) != 230 || meta["build"] != "1.60.1" {
		t.Fatalf("list: %v %d %v", err, len(rows), meta)
	}
	if idOf(rows[0]) != "1000" {
		t.Fatalf("idOf: %s", idOf(rows[0]))
	}

	dir := t.TempDir()
	ids := []string{"1001", "1002", "1005", "1003"}
	atomic.StoreInt32(&limited, 1) // first detail call is rate limited, then retried
	n, err := c.details("quests", ids, dir, false)
	if err != nil || n != 4 {
		t.Fatalf("details: %v %d", err, n)
	}
	if !exists(filepath.Join(dir, "1001.json")) || exists(filepath.Join(dir, "1005.json")) {
		t.Fatal("details files")
	}
	b, _ := os.ReadFile(filepath.Join(dir, "1002.json"))
	if !strings.Contains(string(b), "3143") {
		t.Fatalf("detail content: %s", b)
	}
	before := atomic.LoadInt32(&hits)
	n, _ = c.details("quests", ids, dir, false)
	if n != 0 && n != 1 { // 1005 was a 404, so it's tried again
		t.Fatalf("resume: %d", n)
	}
	if atomic.LoadInt32(&hits)-before > 1 {
		t.Fatal("resume re-downloaded saved quests")
	}

	if _, err := c.get("/daily", nil); !errors.Is(err, errDaily) {
		t.Fatalf("daily: %v", err)
	}
	bad := &client{key: "fdb_bad", http: srv.Client(), interval: time.Millisecond, base: srv.URL}
	if _, err := bad.get("/quests", nil); !errors.Is(err, errAuth) {
		t.Fatalf("auth: %v", err)
	}
}

func TestPacing(t *testing.T) {
	var hits, limited int32
	srv := mock(t, &hits, &limited)
	defer srv.Close()
	c := &client{key: "fdb_good", http: srv.Client(), interval: 50 * time.Millisecond, base: srv.URL}
	start := time.Now()
	for i := 0; i < 5; i++ {
		c.get("/quests/1", nil)
	}
	if time.Since(start) < 200*time.Millisecond {
		t.Fatal("requests weren't paced")
	}
}

func TestDailyHeader(t *testing.T) {
	if dailyLeft("9876/10000") != 124 || dailyLeft("remaining=50") != 50 || dailyLeft("") != -1 {
		t.Fatal("dailyLeft")
	}
}

// The real API's answers: X-Daily-Remaining, and a message that doesn't say "daily".
func TestDailyLimitFromRealHeaders(t *testing.T) {
	minute := []byte(`{"error":{"code":"rate_limit","message":"Slow down: this key allows 60 requests a minute."}}`)
	h := http.Header{}
	h.Set("X-Daily-Remaining", "0")
	if !isDailyLimit(h, minute) {
		t.Fatal("0 left today is the daily limit")
	}
	h.Set("X-Daily-Remaining", "9000")
	if isDailyLimit(h, minute) {
		t.Fatal("the per-minute limit with plenty left today only needs a wait")
	}

	var calls int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		atomic.AddInt32(&calls, 1)
		w.Header().Set("X-Daily-Remaining", "0")
		w.Header().Set("Retry-After", "0")
		w.WriteHeader(429)
		w.Write(minute)
	}))
	defer srv.Close()
	c := &client{key: "k", http: srv.Client(), interval: time.Millisecond, base: srv.URL}
	if _, err := c.get("/quests", nil); !errors.Is(err, errDaily) {
		t.Fatalf("stops at the daily limit: %v", err)
	}
	if atomic.LoadInt32(&calls) != 1 {
		t.Fatal("it shouldn't keep asking once the day is used up")
	}
}

// questServer lists n quests, whole or bare, and counts requests for single quests.
func questServer(n int, whole func(i int) bool, pages *int32) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/quests/") {
			atomic.AddInt32(pages, 1)
			json.NewEncoder(w).Encode(map[string]interface{}{"data": map[string]interface{}{"id": strings.TrimPrefix(r.URL.Path, "/quests/")}})
			return
		}
		var data []map[string]interface{}
		for i := 0; i < n; i++ {
			row := map[string]interface{}{"id": 1000 + i, "name": fmt.Sprintf("Q%d", i)}
			if whole(i) {
				row["starts"], row["ends"], row["chain"] = map[string]interface{}{"id": 1}, nil, map[string]interface{}{}
			}
			data = append(data, row)
		}
		json.NewEncoder(w).Encode(map[string]interface{}{"data": data, "meta": map[string]interface{}{"total": n, "build": "1.60.1"}})
	}))
}

func TestQuestsSkipsPagesWhenTheListHasItAll(t *testing.T) {
	always := func(int) bool { return true }
	cases := []struct {
		name  string
		whole func(int) bool
		force bool
		pages int32
	}{
		{"whole list", always, false, 0},
		{"asked for pages", always, true, 3},
		{"bare list falls back", func(int) bool { return false }, false, 3},
		{"one bare row falls back", func(i int) bool { return i != 2 }, false, 3},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var pages int32
			srv := questServer(3, tc.whole, &pages)
			defer srv.Close()
			dir := t.TempDir()
			c := &client{key: "k", http: srv.Client(), interval: time.Millisecond, base: srv.URL}
			total, n, err := c.quests(nil, dir, tc.force, false)
			if err != nil || total != 3 {
				t.Fatalf("quests: %v %d", err, total)
			}
			if atomic.LoadInt32(&pages) != tc.pages || int32(n) != tc.pages {
				t.Fatalf("pages fetched %d, counted %d, wanted %d", pages, n, tc.pages)
			}
			var saved struct {
				Meta map[string]interface{}   `json:"meta"`
				Data []map[string]interface{} `json:"data"`
			}
			b, err := os.ReadFile(filepath.Join(dir, "quests_list.json"))
			if err != nil || json.Unmarshal(b, &saved) != nil {
				t.Fatalf("list not saved: %v", err)
			}
			if len(saved.Data) != 3 || saved.Meta["build"] != "1.60.1" {
				t.Fatalf("saved list: %s", b)
			}
		})
	}
}

func TestListIsComplete(t *testing.T) {
	row := func(s string) json.RawMessage { return json.RawMessage(s) }
	whole := row(`{"id":1,"starts":null,"ends":{},"chain":{}}`)
	if !listIsComplete([]json.RawMessage{whole, whole}) {
		t.Fatal("a null field still means the list has it")
	}
	if listIsComplete(nil) {
		t.Fatal("an empty list isn't complete")
	}
	for _, bad := range []string{`{"id":1,"ends":{},"chain":{}}`, `{"id":1,"starts":{},"chain":{}}`, `{"id":1,"starts":{},"ends":{}}`, `[1]`} {
		if listIsComplete([]json.RawMessage{whole, row(bad)}) {
			t.Fatalf("incomplete row accepted: %s", bad)
		}
	}
}
