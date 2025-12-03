#ifndef RADIX_HEAP_SOLVER_H
#define RADIX_HEAP_SOLVER_H

#include "solver.h"
#include <vector>
#include <algorithm>
#include <limits>

class RadixHeapSolver : public ShortestPathSolver {
private:
    struct Item { long long key; int u; };
    std::vector<std::vector<Item>> buckets;
    long long last_dist;
    int size_count;

    inline int get_bucket_index(long long last, long long key) {
        unsigned long long diff = (unsigned long long)(last ^ key);
        if (diff == 0) return 0;
        return 64 - __builtin_clzll(diff);
    }

public:
    RadixHeapSolver(const Graph& g) : ShortestPathSolver(g) {
        buckets.resize(65); // 0..64
    }

    void compute(int source, int target = -1) override {
        resetDistances();
        dist[source] = 0;

        for (auto &b : buckets) b.clear();
        last_dist = 0;
        size_count = 0;

        buckets[0].push_back({0, source});
        size_count++;

        while (size_count > 0) {
            int bucket_idx = 0;
            while (bucket_idx < (int)buckets.size() && buckets[bucket_idx].empty()) bucket_idx++;
            if (bucket_idx == (int)buckets.size()) break;

            if (bucket_idx > 0) {
                // 1) min over stored keys
                long long min_key = std::numeric_limits<long long>::max();
                for (const Item &it : buckets[bucket_idx]) {
                    if (it.key < min_key) min_key = it.key;
                }
                last_dist = min_key;

                // 2) wyciągamy kubełek
                std::vector<Item> move = std::move(buckets[bucket_idx]);
                // fizycznie usuwamy te wpisy
                buckets[bucket_idx].clear();
                size_count -= (int)move.size();

                // 3) re-bucketujemy ważne wpisy
                for (const Item &it : move) {
                    int u = it.u;
                    long long k = it.key;
                    // przeterminowane, jeśli stored key != current dist
                    if (k != dist[u]) continue;
                    int new_idx = get_bucket_index(last_dist, k);
                    buckets[new_idx].push_back(it);
                    size_count++;
                }
                continue;
            }

            // bucket 0
            while (!buckets[0].empty()) {
                Item it = buckets[0].back();
                buckets[0].pop_back();
                size_count--;

                int u = it.u;
                long long k = it.key;
                if (k != dist[u]) continue; // stale

                if (u == target) return;

                for (const auto &edge : graph.adj[u]) {
                    int v = edge.target;
                    long long w = edge.weight;
                    long long nd = dist[u] + w;
                    if (nd < dist[v]) {
                        dist[v] = nd;
                        int idx = get_bucket_index(last_dist, nd);
                        buckets[idx].push_back({nd, v});
                        size_count++;
                    }
                }
            }
        }
    }
};

#endif
