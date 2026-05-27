#pragma once

#include "json.hpp"
#include <vector>
using json = nlohmann::json;

class IObserver {
private:

public:
    virtual ~IObserver() = default;
    
    virtual void update(json data, std::vector<int> recipients) = 0;
};
