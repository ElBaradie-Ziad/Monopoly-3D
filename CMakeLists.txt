cmake_minimum_required(VERSION 3.10)
project(MonopolyServer)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# --- 1) RECHERCHE DES DÉPENDANCES SYSTÈME ---
# On fait cela AVANT d'ajouter des flags exotiques (ASAN, Mold) 
# pour ne pas casser les tests internes de compilation de CMake
set(CMAKE_THREAD_PREFER_PTHREAD TRUE)
set(THREADS_PREFER_PTHREAD_FLAG TRUE)
find_package(Threads REQUIRED)
find_package(OpenSSL REQUIRED)

# --- 2) OPTIMISATIONS DE COMPILATION ---

# CCACHE : Accélère les recompilations
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
endif()

# MOLD : Linker ultra-rapide (Conditionnel pour Docker !)
find_program(MOLD_PROGRAM mold)
if(MOLD_PROGRAM)
    message(STATUS "Mold linker trouvé, utilisation de mold.")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fuse-ld=mold")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -fuse-ld=mold")
else()
    message(STATUS "Mold linker non trouvé (normal dans Docker), utilisation du linker standard.")
endif()

# ASAN & DEBUG : Détection des fuites mémoire et erreurs de segmentation
option(USE_ASAN "Activer AddressSanitizer (ralentit la compilation)" ON)
if(USE_ASAN)
    message(STATUS "AddressSanitizer activé.")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -g")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
else()
    message(STATUS "AddressSanitizer désactivé pour plus de rapidité.")
endif()

# TEST_MODE : Active les dés truqués et hooks de test (désactivé par défaut)
option(USE_TEST_MODE "Activer le mode TEST_MODE (dés truqués, etc.)" OFF)
if(USE_TEST_MODE)
    message(STATUS "Mode TEST_MODE activé (DANGER: dés truqués activés !)")
endif()

# On ignore les alertes de dépréciation OpenSSL 3.0
add_definitions(-Wno-deprecated-declarations)

# --- 2.5) PRECOMPILED HEADERS (PCH) ---
# Accélère massivement la compilation en ne parsant qu'une seule fois les gros headers
set(PCH_HEADERS
    "server/libs/json/json.hpp"
    <vector>
    <string>
    <memory>
    <iostream>
    <thread>
    <mutex>
    <map>
    <algorithm>
)

# --- 3) LIBRAIRIE INTERNE (monopoly_lib) ---
file(GLOB_RECURSE LIB_SOURCES 
    "server/core/*.cpp" 
    "server/logic/*.cpp" 
    "server/models/*.cpp" 
    "server/network/*.cpp" 
    "server/protocol/*.cpp" 
    "database/access/*.cpp"
)

add_library(monopoly_lib STATIC ${LIB_SOURCES})
target_precompile_headers(monopoly_lib PRIVATE ${PCH_HEADERS})

target_include_directories(monopoly_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/server/core
    ${CMAKE_CURRENT_SOURCE_DIR}/server/models
    ${CMAKE_CURRENT_SOURCE_DIR}/server/models/player
    ${CMAKE_CURRENT_SOURCE_DIR}/server/models/tile
    ${CMAKE_CURRENT_SOURCE_DIR}/server/network
    ${CMAKE_CURRENT_SOURCE_DIR}/server/protocol
    ${CMAKE_CURRENT_SOURCE_DIR}/database/access
    ${CMAKE_CURRENT_SOURCE_DIR}/server/logic
    ${CMAKE_CURRENT_SOURCE_DIR}/server/logic/commands
    ${CMAKE_CURRENT_SOURCE_DIR}/server/logic/commands/Game
    ${CMAKE_CURRENT_SOURCE_DIR}/server/logic/commands/Lobby
    ${CMAKE_CURRENT_SOURCE_DIR}/server/logic/controllers
    ${CMAKE_CURRENT_SOURCE_DIR}/server/libs
    ${CMAKE_CURRENT_SOURCE_DIR}/server/logic/match
    ${CMAKE_CURRENT_SOURCE_DIR}/server/libs/asio
    ${CMAKE_CURRENT_SOURCE_DIR}/server/libs/json
)

target_link_libraries(monopoly_lib PUBLIC 
    Threads::Threads 
    pqxx 
    pq 
    OpenSSL::SSL 
    OpenSSL::Crypto
)

# Active TEST_MODE si l'option est cochée
if(USE_TEST_MODE)
    target_compile_definitions(monopoly_lib PUBLIC TEST_MODE)
endif()

# --- 4) EXÉCUTABLE SERVEUR ---
add_executable(MonopolyServer server/main.cpp)
target_link_libraries(MonopolyServer PRIVATE monopoly_lib)

# Alias pour compiler uniquement le serveur avec 'make server'
add_custom_target(server DEPENDS MonopolyServer)

# --- 5) SECTION TESTS ---
file(GLOB_RECURSE TEST_SOURCES "${CMAKE_SOURCE_DIR}/server/tests/*.cpp")

if(TEST_SOURCES)
    message(STATUS "Tests trouvés : ${TEST_SOURCES}")
    add_executable(MonopolyTests ${TEST_SOURCES})
    target_precompile_headers(MonopolyTests PRIVATE ${PCH_HEADERS})

    target_include_directories(MonopolyTests PRIVATE
        ${CMAKE_SOURCE_DIR}/server/core
        ${CMAKE_SOURCE_DIR}/server/models
        ${CMAKE_SOURCE_DIR}/server/models/tile
        ${CMAKE_SOURCE_DIR}/server/network
        ${CMAKE_SOURCE_DIR}/server/protocol
        ${CMAKE_SOURCE_DIR}/database/access
        ${CMAKE_SOURCE_DIR}/server/logic
        ${CMAKE_SOURCE_DIR}/server/logic/commands
        ${CMAKE_SOURCE_DIR}/server/logic/commands/Game
        ${CMAKE_SOURCE_DIR}/server/logic/commands/Lobby
        ${CMAKE_SOURCE_DIR}/server/logic/controllers
        ${CMAKE_SOURCE_DIR}/server/logic/match
        ${CMAKE_SOURCE_DIR}/server/tests/
        ${CMAKE_SOURCE_DIR}/server/tests/game/
        ${CMAKE_SOURCE_DIR}/server/libs
        "/usr/include/UnitTest++"
    )

    target_include_directories(MonopolyTests SYSTEM PRIVATE
        ${CMAKE_SOURCE_DIR}/server/libs/asio
        ${CMAKE_SOURCE_DIR}/server/libs
        ${CMAKE_SOURCE_DIR}/server/libs/json
    )

    target_link_libraries(MonopolyTests PRIVATE 
        monopoly_lib 
        UnitTest++
        OpenSSL::SSL 
        OpenSSL::Crypto
        Threads::Threads
    )

    # Active le mode test : dés truqués, hooks de test, etc.
    target_compile_definitions(MonopolyTests PRIVATE TEST_MODE)

    # Alias pour compiler uniquement les tests avec 'make test'
    add_custom_target(test DEPENDS MonopolyTests)

    # Alias existant 'make tests' qui compile ET lance les tests
    add_custom_target(tests 
        COMMAND ./MonopolyTests
        DEPENDS MonopolyTests
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
        COMMENT "Compilation et exécution des tests..."
    )
endif()
