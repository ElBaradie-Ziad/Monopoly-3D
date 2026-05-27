#include "SessionManager.hpp"

int SessionManager::addNewSession(ConnectionHandle hdl) {
    int newID = nextSession++;

    sessions.emplace(newID, Session(hdl));
    handleToIDMap[hdl] = newID;

    return newID;
}

void SessionManager::removeSessionByHandle(ConnectionHandle hdl) {
    auto it = handleToIDMap.find(hdl);

    // Check if the connection exists
    if (it != handleToIDMap.end()) {
        
        // Extract the clientID from the map iterator
        int clientID = it->second; 

        // 3. Erase the data from both maps
        sessions.erase(clientID);
        handleToIDMap.erase(it);
    }
}

Session* SessionManager::getSession(int clientID) {
    auto it = sessions.find(clientID);

    if (it != sessions.end())
        return &(it->second);
    
    return nullptr;
}
