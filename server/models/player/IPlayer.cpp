#include "IPlayer.hpp"
#include <stdexcept>

IPlayer::IPlayer(int id, const std::string& name, int moneyStart) : id(id), playerName(name), money(moneyStart) {
    abilityState = std::make_unique<StandardAbility>();
}

void IPlayer::setPlayerClass(int classID) {
    switch (classID) {
    case Codes::PlayerClass::THIEF:
        abilityState = std::make_unique<ThiefAbility>();
        break;
    case Codes::PlayerClass::LUCKY:
        abilityState = std::make_unique<LuckyAbility>();
        break;
    case Codes::PlayerClass::GREEDY:
        abilityState = std::make_unique<GreedyAbility>();
        break;
    default:
        abilityState = std::make_unique<StandardAbility>();
    }
}

void IPlayer::move(int cases) {
    const int BOARD_SIZE = 40;
    position = (position + cases) % BOARD_SIZE;
    if (position < 0) position += BOARD_SIZE;
}

void IPlayer::addMoney(int amount) {
    if (amount >= 0) {
        money += amount;
        return;
    } 
    throw std::runtime_error("impossible d'ajouter de l'argent négatif");
}

void IPlayer::removeMoney(int amount) {
    if (amount < 0) 
        throw std::runtime_error("impossible de retirer de l'argent négatif");
    
    money -= amount;
    if (money < 0) {
        // Faillite : le joueur n'a plus assez pour payer
        isEliminated = true;
        money = 0;
    }
}

void IPlayer::setIsReady() {
    this->isReady = true;
}

void IPlayer::setReadyToStartGame() {
    this->readyToStartGame = true;
}

void IPlayer::setNotReady() {
    this->isReady = false;
}

bool IPlayer::checkIsReady() const {
    return isReady;
}

bool IPlayer::checkIsReadyToStartGame() const {
    return readyToStartGame;
}

void IPlayer::setHasRolledDice(bool state) {
    this->hasRolledDice = state;
}

bool IPlayer::getHasRolledDice() const {
    return this->hasRolledDice;
}

// ─── Correction du bug ────────────────────────────────────────────────
// Avant : this->inJail = false  ← bug, le joueur n'était jamais mis en prison
// Après : this->inJail = true   ← correct
void IPlayer::placeInJail() {
    this->inJail = true;    // le joueur EST en prison
    this->jailTime = 0;     // compteur repart à zéro
    this->position = 10;    // case prison sur le plateau Monopoly
}

void IPlayer::freeFromJail() {
    this->inJail = false;
    this->jailTime = 0;     // remet le compteur à zéro à la sortie
}

bool IPlayer::checkIfInJail() const {
    return this->inJail;
}

void IPlayer::incrementDoubleCount() {
    this->doubleCount++;
}

int IPlayer::getDoubleCount() const {
    return this->doubleCount;
}

void IPlayer::resetDoubleCount() {
    this->doubleCount = 0;
}

bool IPlayer::getIsEliminated() const {
    return this->isEliminated;
}

void IPlayer::incrementTurnsInJail() {
    this->jailTime++;
}

int IPlayer::getMoney() const {
    return this->money;
}


int IPlayer::getPosition() const {
    return this->position;
}

void IPlayer::setPosition(int pos) {
    this->position = pos;
}

int IPlayer::getJailTime() const {
    return this->jailTime;
}

bool IPlayer::isBankrupt() const {
    return this->isEliminated;
}
