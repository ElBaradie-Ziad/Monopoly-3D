#pragma once

#include "json.hpp"
#include "Code.hpp"

using json = nlohmann::json;

struct Message {
    Codes::MainID mainID;
    int subID;
    int clientID;
    json data;
    
    Message(Codes::MainID mID, int sID, int cID, json p) 
        : mainID(mID), subID(sID), clientID(cID), data(p) {}
};
