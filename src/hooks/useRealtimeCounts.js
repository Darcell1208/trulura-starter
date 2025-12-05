// src/hooks/useRealtimeCounts.js
import { useEffect, useMemo, useState } from "react";
import { supabase } from "../lib/supabase";

export default function useRealtimeCounts() {
  const [counts, setCounts] = useState({
    glows: 0,
    sparks: 0,
    vents: 0,
    moods: 0,
    loading: true,
    error: null,
  });

  // initial fetch
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const [glowRes, sparkRes, ventRes, moodRes] = await Promise.all([
          supabase.from("glow_sessions").select("*", { count: "exact", head: true }),
          supabase.from("sparks").select("*", { count: "exact", head: true }),
          supabase.from("vents").select("*", { count: "exact", head: true }),
          supabase.from("moods").select("*", { count: "exact", head: true }),
        ]);
        if (!cancelled) {
          setCounts((c) => ({
            ...c,
            glows: glowRes.count ?? 0,
            sparks: sparkRes.count ?? 0,
            vents: ventRes.count ?? 0,
            moods: moodRes.count ?? 0,
            loading: false,
            error: null,
          }));
        }
      } catch (err) {
        if (!cancelled) setCounts((c) => ({ ...c, loading: false, error: err?.message || "Load error" }));
      }
    })();
    return () => { cancelled = true; };
  }, []);

  // realtime updates
  useEffect(() => {
    const channel = supabase
      .channel("creator_counts")
      .on("postgres_changes", { event: "*", schema: "public", table: "glow_sessions" }, refresh)
      .on("postgres_changes", { event: "*", schema: "public", table: "sparks" }, refresh)
      .on("postgres_changes", { event: "*", schema: "public", table: "vents" }, refresh)
      .on("postgres_changes", { event: "*", schema: "public", table: "moods" }, refresh)
      .subscribe();

    async function refresh(payload) {
      const table = payload.table;
      const { count } = await supabase.from(table).select("*", { count: "exact", head: true });
      setCounts((c) => ({
        ...c,
        [table === "glow_sessions" ? "glows" : table]: count ?? 0,
      }));
    }

    return () => { supabase.removeChannel(channel); };
  }, []);

  return useMemo(() => counts, [counts]);
}
