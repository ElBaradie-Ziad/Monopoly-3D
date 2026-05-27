#pragma once
#include <atomic>
#include "MatchManager.hpp"

void runPlayer1GameSequence(std::atomic<int>& sharedMatchID, MatchManager* mm);
