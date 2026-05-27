#pragma once
#include "IBaseTile.hpp"

class TaxTile : public IBaseTile {
private:
    int taxAmount;

public:
    TaxTile(const std::string& name, int amount) 
        : IBaseTile(name, ETileType::TAX), taxAmount(amount) {}

    int getTax() const { return taxAmount; }
};
