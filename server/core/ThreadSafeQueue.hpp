#pragma once

#include <queue>
#include <mutex>
#include <condition_variable>
#include "Message.hpp"

class ThreadSafeQueue {
private:
    std::queue<Message> queue;
    std::mutex mutex;
    std::condition_variable cv;

public:
    ThreadSafeQueue() = default;
    ~ThreadSafeQueue() = default;
    
    void push(Message msg);
    
    Message pop();
};
