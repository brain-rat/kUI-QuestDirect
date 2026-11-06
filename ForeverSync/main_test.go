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
