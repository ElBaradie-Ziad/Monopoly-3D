#include "ThreadSafeQueue.hpp"

void ThreadSafeQueue::push(Message msg) {
    std::unique_lock<std::mutex> lock(mutex);

    queue.push(msg);

    lock.unlock();
    
    cv.notify_one();
}

Message ThreadSafeQueue::pop() {
    std::unique_lock<std::mutex> lock(mutex);

    while (queue.empty())
        cv.wait(lock);
    
    Message msg = queue.front();
    queue.pop();
    
    lock.unlock();
    
    return msg;
}
