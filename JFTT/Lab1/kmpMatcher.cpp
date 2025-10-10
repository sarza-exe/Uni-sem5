#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <fstream>
using namespace std;

// Algorithm from "Introduction to Algorithms" chapter 32.4

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
            //cout << "Pattern occurs with shift " << i-m+1 << "\n";
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