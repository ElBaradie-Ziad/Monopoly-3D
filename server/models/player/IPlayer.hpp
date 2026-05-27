#pragma once

#include <memory>
#include "IPlayerAbility.hpp"

class IPlayer {
protected:
    bool isReady = false;
    bool readyToStartGame = false;
    int id = -1;
    int money = 1500;
    int position = 0;
    bool inJail = false;
    int jailTime = 0;
    bool isEliminated = false;
    bool hasRolledDice = false;
    int doubleCount = 0;
    std::unique_ptr<IPlayerAbility> abilityState;

    std::string playerName;
    std::string token;
    std::vector<int> cards;

public:

    IPlayer(int id, const std::string& name, int moneyStart);
    virtual ~IPlayer() = default;

    virtual int getId() const { return id; }
    virtual std::string getName() const { return playerName; }
    virtual std::string getToken() const { return token; }
    virtual Codes::PlayerClass getPlayerClass() const { 
        return abilityState ? abilityState->getClassType() : Codes::PlayerClass::STANDARD; 
    }

    virtual void setPlayerClass(int classID);

    virtual int getMoney() const;
    virtual void addMoney(int amount);
    virtual void removeMoney(int amount);
    virtual bool isBankrupt() const;
    virtual bool getIsEliminated() const;

    virtual int getPosition() const;
    virtual void setPosition(int pos);
    virtual void move(int cases);

    virtual bool checkIfInJail() const;
    virtual void placeInJail();
    virtual void freeFromJail();
    virtual int getJailTime() const;
    virtual void incrementTurnsInJail();

    virtual bool checkIsReady() const;
    virtual bool checkIsReadyToStartGame() const;
    virtual void setIsReady();
    virtual void setReadyToStartGame();
    virtual void setNotReady();

    virtual bool getHasRolledDice() const;
    virtual void setHasRolledDice(bool state);

    virtual int getDoubleCount() const;
    virtual void incrementDoubleCount();
    virtual void resetDoubleCount();

    virtual std::vector<int>& getCards() { return cards; }
    virtual const std::vector<int>& getCards() const { return cards; }

    // Hooks (Delegated to State)
    virtual void onSameTileAs(IPlayer& other) {
        if (abilityState) abilityState->onSameTileAs(*this, other);
    }
    virtual void onRollDouble() {
        if (abilityState) abilityState->onRollDouble(*this);
    }
    virtual void onPassStart() {
        if (abilityState) abilityState->onPassStart(*this);
    }
};
