#pragma once
#include <atomic>
#include "MatchManager.hpp"

void runPlayer1LobbySequence(std::atomic<int>& sharedMatchID, MatchManager* mm);
