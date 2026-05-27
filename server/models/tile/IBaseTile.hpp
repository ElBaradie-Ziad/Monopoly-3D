#pragma once

#include "ITile.hpp"
#include <string>

class IBaseTile : public ITile {
protected:
    std::string name;
    ETileType type;

public:
    IBaseTile(const std::string& name, ETileType type) : name(name), type(type) {}
    virtual ~IBaseTile() = default;

    std::string getName() const override { return name; }
    ETileType getType() const override { return type; }
};
