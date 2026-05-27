#pragma once

#include <string>
#include <optional>

struct User {
    int id;
    std::string user_name;
    std::string password_hash;
    std::string created_at;
    std::optional<std::string> last_login;
};