#pragma once

#include "ETileType.hpp"
#include <string>

class ITile {
public:
    virtual ~ITile() = default;
    virtual std::string getName() const = 0;
    virtual ETileType getType() const = 0;
};
