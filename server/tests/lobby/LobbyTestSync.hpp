#pragma once
#include <atomic>

// Synchronisation flags between player sequences and the test verifier.
// Set by P1/P2 threads, read by ThreadedLobbyTests.
extern std::atomic<bool> p2Joined;
extern std::atomic<bool> p1MarkedReady;
extern std::atomic<bool> p2MarkedReady;
extern std::atomic<bool> gameStarted;
