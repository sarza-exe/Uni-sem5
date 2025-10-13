#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <fstream>
#include <unordered_map>
#include <bits/stdc++.h>

using namespace std;

// Algorithm from "Introduction to Algorithms" chapter 32.3

// length in bytes of the first utf-8 character starting with c
int utf8_char_len(unsigned char c) {
    if (c < 0x80) return 1;
    if ((c >> 5) == 0x6) return 2;   // 110xxxxx
    if ((c >> 4) == 0xE) return 3;   // 1110xxxx
    if ((c >> 3) == 0x1E) return 4;  // 11110xxx
    return 1;
}

bool isSuffix(const string &pattern, int k, int q, const string &aStr) {
    if (k == 0) return true;

    vector<string> prefSymbols;
    prefSymbols.reserve(k);
    int i = 0;
    int count = 0;
    while (i < pattern.size() && count < k) {
        int w = utf8_char_len(static_cast<unsigned char>(pattern[i]));
        if (i + w > pattern.size()) w = 1;
        prefSymbols.emplace_back(pattern.substr(i, w));
        i += w;
        ++count;
    }
    if ((int)prefSymbols.size() < k) return false;

    vector<string> sSymbols;
    sSymbols.reserve(q + 1);
    i = 0;
    count = 0;
    while (i < pattern.size() && count < q) {
        int w = utf8_char_len(static_cast<unsigned char>(pattern[i]));
        if (i + w > pattern.size()) w = 1;
        sSymbols.emplace_back(pattern.substr(i, w));
        i += w;
        ++count;
    }
    if (!aStr.empty()) sSymbols.push_back(aStr);

    if ((int)sSymbols.size() < k) return false; 

    int start = (int)sSymbols.size() - k;
    for (int j = 0; j < k; ++j) {
        if (sSymbols[start + j] != prefSymbols[j]) return false;
    }
    return true;
}

int GetLength(const string& str)
{
    int len = 0;
    int i = 0;
    while(i < str.size())
    {
        len++;
        int w = utf8_char_len(static_cast<unsigned char>(str[i]));
        i += w;
    }
    return len;
}

vector<vector<int>> ComputeTransitionFunction(const string& pattern, const string& sigma, unordered_map<string,int> sigma_map, int sigmaSize)
{
    const int m = static_cast<int>(GetLength(pattern));
    vector<vector<int>> delta(m+1, vector<int>(static_cast<int>(sigmaSize), 0));

    for(int q = 0; q <= m; q++)
    {
        for(int i = 0; i < sigma.length();) //character a
        {
            int w = utf8_char_len(static_cast<unsigned char>(sigma[i]));
            string a = sigma.substr(i, w);
            int k = min(q+2, m+1);
            do{
                k = k-1;
            } while(!isSuffix(pattern, k, q, a));
            delta[q][sigma_map.at(a)] = k;
            i += w;
        }
    }
    return delta;
}

void FiniteAutomatonMatcher(const string& T, vector<vector<int>> delta, unordered_map<string,int> sigma, const int m)
{
    int n = static_cast<int>(T.length());
    int q = 0;
    int occurrences = 0;
    for (int i = 0; i < n;){
        int w = utf8_char_len(static_cast<unsigned char>(T[i]));
        string a = T.substr(i, w);
        if(sigma.count(a)) q = delta[q][sigma.at(a)];
        else q = 0;
        if(q == m){
            occurrences++;
            //cout << "Pattern occurs with shift " << i-m+1 << "\n";
        }
        i+=w;
    }
    cout << "Pattern occurs " << occurrences << " times.\n";
}

int main(int argc, char* argv[]) {
    if (argc != 3){
        cerr << "Try: ./FA <pattern> <file_name>\n";
    }

    string pattern = argv[1];
    const string filename = argv[2];

    std::ifstream file(filename);
    if (!file) {
        std::cerr << "Could not open file: " << filename << "\n";
        return 1;
    }

    std::string text((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());

    unordered_map<string,int> sigma_map = {};
    string sigma = "";
    int index = 0;
    
    for(int i = 0; i < pattern.length();)
    {
        int w = utf8_char_len(static_cast<unsigned char>(pattern[i]));
        string a = pattern.substr(i, w);
        if(!sigma_map.count(a)) {
            sigma_map[a] = index;
            sigma.append(a);
            index++;
        }
        i += w;
    }

    auto delta = ComputeTransitionFunction(pattern, sigma, sigma_map, index);

    cout<<"Delta function:\n";
    for (const auto& row : delta) {
        for (int val : row)
            std::cout << val << ' ';
        std::cout << '\n';
    }

    FiniteAutomatonMatcher(text, delta, sigma_map, GetLength(pattern));
    return 0;
}