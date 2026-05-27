#pragma once
#include <atomic>
#include "MatchManager.hpp"

void runPlayer2LobbySequence(std::atomic<int>& sharedMatchID, MatchManager* mm);
