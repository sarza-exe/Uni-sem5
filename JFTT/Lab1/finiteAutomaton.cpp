#include <iostream>
#include <string>
#include <vector>
#include <algorithm>
#include <fstream>
using namespace std;

// Algorithm from "Introduction to Algorithms" chapter 32.3

bool isSuffix(const string pattern, int k, int q, const char a){
    if(k == 0) return true;

    string w = pattern.substr(0, q);
    w.push_back(a);
    int index = k-1;
    for(int i = q; i >= 0; i--){
        if(pattern[index] != w[i]) return false;
        index -= 1;
        if(index == -1) break;
    }

    return true;
}

vector<vector<int>> ComputeTransitionFunction(const string& pattern, const string& sigma)
{
    const int m = static_cast<int>(pattern.length());
    vector<vector<int>> delta(m+1, vector<int>(static_cast<int>(sigma.length()), 0));

    for(int q = 0; q <= m; q++)
    {
        for(int a = 0; a < sigma.length(); a++)
        {
            int k = min(q+2, m+1);
            do{
                k = k-1;
            } while(!isSuffix(pattern, k, q, sigma[a]));
            delta[q][a] = k;
        }
    }

    return delta;
}

void FiniteAutomatonMatcher(const string& T, vector<vector<int>> delta, const int m)
{
    int n = static_cast<int>(T.length());
    int q = 0;
    int occurrences = 0;
    for (int i = 0; i < n; i++){
        q = delta[q][static_cast<int>(T[i]) - 97];
        if(q == m){
            occurrences++;
            //cout << "Pattern occurs with shift " << i-m+1 << "\n";
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

    const string sigma = "abcdefghijklmnopqrstuvwxyz";
    auto delta = ComputeTransitionFunction(pattern, sigma);

    cout<<"Delta function:\n";
    for (const auto& row : delta) {
        for (int val : row)
            std::cout << val << ' ';
        std::cout << '\n';
    }

    FiniteAutomatonMatcher(text, delta, pattern.length());
    return 0;
}