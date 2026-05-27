#pragma once
#include <atomic>
#include "MatchManager.hpp"

void runPlayer2GameSequence(std::atomic<int>& sharedMatchID, MatchManager* mm);
