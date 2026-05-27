#pragma once

#include "Code.hpp"

class IPlayer;

class IPlayerAbility {
public:
    virtual ~IPlayerAbility() = default;
    virtual void onSameTileAs(IPlayer& context, IPlayer& other) = 0;
    virtual void onRollDouble(IPlayer& context) = 0;
    virtual void onPassStart(IPlayer& context) = 0;
    virtual Codes::PlayerClass getClassType() const = 0;
};

class StandardAbility : public IPlayerAbility {
public:
    void onSameTileAs(IPlayer& context, IPlayer& other) override {}
    void onRollDouble(IPlayer& context) override {}
    void onPassStart(IPlayer& context) override;
    Codes::PlayerClass getClassType() const override { return Codes::PlayerClass::STANDARD; }
};

class ThiefAbility : public IPlayerAbility {
public:
    void onSameTileAs(IPlayer& context, IPlayer& other) override;
    void onRollDouble(IPlayer& context) override {}
    void onPassStart(IPlayer& context) override;
    Codes::PlayerClass getClassType() const override { return Codes::PlayerClass::THIEF; }
};

class LuckyAbility : public IPlayerAbility {
public:
    void onSameTileAs(IPlayer& context, IPlayer& other) override {}
    void onRollDouble(IPlayer& context) override;
    void onPassStart(IPlayer& context) override;
    Codes::PlayerClass getClassType() const override { return Codes::PlayerClass::LUCKY; }
};

class GreedyAbility : public IPlayerAbility {
public:
    void onSameTileAs(IPlayer& context, IPlayer& other) override {}
    void onRollDouble(IPlayer& context) override {}
    void onPassStart(IPlayer& context) override;
    Codes::PlayerClass getClassType() const override { return Codes::PlayerClass::GREEDY; }
};
