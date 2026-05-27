#include "IPlayerAbility.hpp"
#include "IPlayer.hpp"

// Standard
void StandardAbility::onPassStart(IPlayer& context) {
    context.addMoney(200);
}

// Thief
void ThiefAbility::onSameTileAs(IPlayer& context, IPlayer& other) {
    other.removeMoney(200);
    context.addMoney(200);
}
void ThiefAbility::onPassStart(IPlayer& context) {
    context.addMoney(200);
}

// Lucky
void LuckyAbility::onRollDouble(IPlayer& context) {
    context.addMoney(25);
}
void LuckyAbility::onPassStart(IPlayer& context) {
    context.addMoney(200);
}

// Greedy
void GreedyAbility::onPassStart(IPlayer& context) {
    context.addMoney(275);
}
