#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <fstream>
using namespace std;

// Algorithm from "Introduction to Algorithms" chapter 32.4

// length in bytes of the first utf-8 character starting with c
int utf8_char_len(unsigned char c) {
    if (c < 0x80) return 1;
    if ((c >> 5) == 0x6) return 2;   // 110xxxxx
    if ((c >> 4) == 0xE) return 3;   // 1110xxxx
    if ((c >> 3) == 0x1E) return 4;  // 11110xxx
    return 1;
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

void ComputePrefixFunction(const string& pattern, vector<int>& pi)
{
    const int m = static_cast<int>(pattern.length());
    pi.assign(m, 0);
    int k = 0;

    for(int q = 1; q < m; q++)
    {
        while( k > 0 && pattern[k] != pattern[q])
            k = pi[k-1];
        if( pattern[k] == pattern[q]) k += 1;
        pi[q] = k;
    }
}

void KMPMatcher(const string& T, const string& P)
{
    int n = static_cast<int>(T.length());
    int m = static_cast<int>(P.length());
    int patternLen = GetLength(P);
    if (m == 0) {
        cout << "Empty pattern — matches at all " << m << " positions.\n";
        return;
    }
    vector<int> pi;
    ComputePrefixFunction(P, pi);
    int q = 0;
    int occurrences = 0;
    for (int i = 0; i < n; i++){
        while(q > 0 && P[q] != T[i]) {
            q = pi[q-1];
        }
        if(P[q] == T[i])
            q += 1;
        if(q == m){
            occurrences++;
            cout << "Pattern occurs with shift " << GetLength(T.substr(0,i+1))-patternLen << "\n";
            q = pi[q-1];
        }
    }
    cout << "Pattern occurs " << occurrences << " times.\n";
}

int main(int argc, char* argv[]) {
    if (argc != 3){
        cerr << "Try: ./FA <pattern> <file_name>\n";
    }

    const string pattern = argv[1];
    const string filename = argv[2];

    std::ifstream file(filename);
    if (!file) {
        std::cerr << "Could not open file: " << filename << "\n";
        return 1;
    }

    std::string text((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());

    KMPMatcher(text, pattern);
    return 0;
}
