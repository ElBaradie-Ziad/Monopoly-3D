# Server & Client Communication Protocol

## Network Philosophy

The game uses a **deterministic model**. This means the client does not ask the server "Where is my token?". The server only announces key actions (e.g., "Player 1 rolled a 6"). **It is up to the client to calculate the animation, movement, and consequences (paying rent, etc.) using its own scripts.**

-----

## 1\. Global Structure

All exchanged messages are in JSON format and use a standardized "envelope".

### 📤 Client Request (Sent by Client)

The client must always provide a `mainID` (category), a `subID` (specific action), and a `data` object containing parameters.

```json
{
  "mainID": int,
  "subID": int,
  "clientID" : int,
  "data": {
    // ...
  }
}
````

### 📥 Server Response (Direct Response)

When the client makes a request, the server **always** responds with the same envelope, but adds an `erreur` (boolean) field.

**✅ On Success (`erreur: false`) :**

```json
{
  "mainID": int,
  "subID": int,
  "erreur": false,
  "data": {
    // ..
  }
}
```

**❌ On Error (`erreur: true`) :**

```json
{
  "mainID": <int>,
  "subID": <int>,
  "erreur": true,
  "data": {
    "codeErreur": <int>,
    "messageErreur": "<string>"
  }
}
```

### 🔔 Server Push (Asynchronous Event)

A **Server Push** (`mainID: 4`) is an automatic broadcast sent by the server to notify players of real-time events (like dice rolls or turn changes). The `"erreur"` field is generally `false` because these messages report actions that are already confirmed.

```json
{
  "mainID": 4,
  "subID": int,
  "erreur": false,
  "data": {
    "eventType": int, // Specifies the exact event (Used mostly with subID = 2)
    "payload": {
      // Dynamic data depending on the event (e.g., dice values, player names)
    }
  }
}
```

-----

## 2\. Client Actions (Requests & Responses)

> ⚠️ **Note:** The responses illustrated below assume the action was successful (`"erreur": false`). In case of failure, the server will always return `"erreur": true` along with the standard error format (see Section 1).

### ⚪ MAIN ID 0 : Connection / Initialization (Server Push)

**Trigger :** Automatically sent by the server the moment a WebSocket connection is successfully established. 

The client does **not** send a request for this. The server immediately assigns a unique `clientID` to the session. **The client must save this `clientID`** and include it in every subsequent request sent to the server.

**Server Response (Initial Handshake) :**
```json
{
  "mainID": 0,
  "subID": 0,
  "erreur": false,
  "data": {
    "clientID": int
  }
}
```

---

### 🟢 MAIN ID 1 : Authentication

<table>
  <thead>
    <tr>
      <th>Action</th>
      <th>SubID</th>
      <th>Sent by Client (Full Request)</th>
      <th>Server Response (Full Response)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Login</strong></td>
      <td><code>1</code></td>
      <td>
<pre><code>{
  "mainID": 1,
  "subID": 1,
  "clientID": int,
  "data": {
    "username": "string",
    "password": "string"
  }
}</code></pre>
      </td>
      <td>
<pre><code>{
  "mainID": 1,
  "subID": 1,
  "erreur": false,
  "data": {}
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Logout</strong></td>
      <td><code>2</code></td>
      <td>
<pre><code>{
  "mainID": 1,
  "subID": 2,
  "clientID": int,
  "data": {}
}</code></pre>
      </td>
      <td>
<pre><code>{
  "mainID": 1,
  "subID": 2,
  "erreur": false,
  "data": {}
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Register</strong></td>
      <td><code>3</code></td>
      <td>
<pre><code>{
  "mainID": 1,
  "subID": 3,
  "clientID": int,
  "data": {
    "username": "string",
    "password": "string"
  }
}</code></pre>
      </td>
      <td>
<pre><code>{
  "mainID": 1,
  "subID": 3,
  "erreur": false,
  "data": {}
}</code></pre>
      </td>
    </tr>
  </tbody>
</table>

-----

### 🔵 MAIN ID 2 : Lobby (Waiting Rooms)

> 🟨 **BROADCAST EXPLANATION ( YELLOW BOXES ) :** If a server response is enclosed in a **yellow box**, it means this response is a **Broadcast**. The server does not just reply to the player who sent the request, but sends this exact JSON payload to **all players** currently in the lobby or game.
<table>
  <thead>
    <tr>
      <th>Action</th>
      <th>SubID</th>
      <th>Sent by Client (Full Request)</th>
      <th>Server Response to asker</th>
      <th>Server Response to other players</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Create Lobby</strong></td>
      <td><code>1</code></td>
      <td>
<pre><code>{
  "mainID": 2,
  "subID": 1,
  "clientID": int,
  "data": {
    "username": string,
    "mapID": int,
    "numberTurn": int, // -1 for infinite turns 
    "moneyStart": int
  }
}</code></pre>
      </td>
      <td>
<pre><code>{
  "mainID": 2,
  "subID": 1,
  "erreur": false,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre><code>X</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Leave Lobby</strong></td>
      <td><code>2</code></td>
      <td>
<pre><code>{
  "mainID": 2,
  "subID": 2,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre><code>X</code></pre>
      </td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": LOBBY_PLAYER_LEFT,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Join Lobby</strong></td>
      <td><code>3</code></td>
      <td>
<pre><code>{
  "mainID": 2,
  "subID": 3,
  "clientID": int,
  "data": {
    "matchID": int,
    "username": string
  }
}</code></pre>
      </td>
      <td>
<pre><code>{
  "mainID": 2,
  "subID": 3,
  "erreur": false,
  "data": {
    "mapID": int,
    "numberTurn": int, -1 for infinite turns
    "moneyStart": int,  
    "players": [
      { "clientID": int, "username": string, 
      "ready": bool, "classID": int }
    ]
  }
}</code></pre>
      </td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": LOBBY_PLAYER_JOINED,
    "payload": {
      "clientID": int,
      "username": string
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Ready</strong></td>
      <td><code>4</code></td>
      <td>
<pre><code>{
  "mainID": 2,
  "subID": 4,
  "clientID": int,
  "data": {
    "matchID": int,
    "classID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": READY,
    "payload": {
      "clientID": clientID,
      "classID": int
    }
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": READY,
    "payload": {
      "clientID": clientID,
      "classID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Start Game</strong></td>
      <td><code>5</code></td>
      <td>
<pre><code>{
  "mainID": 2,
  "subID": 5,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": TURN_CHANGED,
    "payload": {
      "currentClientID": int
    }
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": TURN_CHANGED,
    "payload": {
      "currentClientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
  </tbody>
</table>

---

### 🔴 MAIN ID 3 : In-Game Actions

> 🟨 **BROADCAST EXPLANATION ( YELLOW BOXES ) :** If a server response is enclosed in a **yellow box**, it means this response is a **Broadcast**. The server does not just reply to the player who sent the request, but sends this exact JSON payload to **all players** currently in the lobby or game.

<table>
  <thead>
    <tr>
      <th>Action</th>
      <th>SubID</th>
      <th>Sent by Client (Full Request)</th>
      <th>Server Response (Full Response)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Roll Dice</strong></td>
      <td><code>1</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 1,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": DICE_ROLLED,
    "payload": {
      "clientID": int,
      "dice1": int,
      "dice2": int,
      "card": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Get out of jail<br>( Pay fee to exit )</strong></td>
      <td><code>2</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 2,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": GOT_OUT_OF_JAIL,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Use a Card<br>( Player uses a card<br>from their inventory )</strong></td>
      <td><code>3</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 3,
  "clientID": int,
  "data": {
    "matchID": int,
    "cardID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": USE_CARD,
    "payload": {
      "clientID": int
      "cardID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Buy Property</strong></td>
      <td><code>4</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 4,
  "clientID": int,
  "data": {
    "matchID": int,
    "propertyID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": PROPERTY_BOUGHT,
    "payload": {
      "clientID": int,
      "propertyID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Build a House</strong></td>
      <td><code>5</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 5,
  "clientID": int,
  "data": {
      "clientID": int,
      "propertyID": int,
      "totalHouses": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": HOUSE_BUILT,
    "payload": {
      "clientID": int,
      "propertyID": int,
      "totalHouses": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>End Turn</strong></td>
      <td><code>6</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 6,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": END_TURN,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Ready for next turn</strong></td>
      <td><code>7</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 7,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": TURN_CHANGED,
    "payload": {
      "currentClientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Start Auction</strong></td>
      <td><code>8</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 8,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": AUCTION_STARTED,
    "payload": {
      "property_id": int,
      "starting_price": int,
      "participants": [int, int, int] // All players
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Place Bid</strong></td>
      <td><code>9</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 9,
  "clientID": int,
  "data": {
    "matchID": int,
    "bid_amount": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": PLACE_BID,
    "payload": {
      "clientID": int,
      "bid_amount": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Leave Auction</strong></td>
      <td><code>10</code></td>
      <td>
<pre><code>{
  "mainID": 3,
  "subID": 10,
  "clientID": int,
  "data": {
    "matchID": int
  }
}</code></pre>
      </td>
      <td>
<pre style="border: 2px solid rgba(255, 252, 53, 0.72);"><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": LEAVE_AUCTION,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
  </tbody>
</table>

-----

## 3\. Events (Server Push) - MAIN ID 4

### ⚡ SubID 1 : SNAPSHOT (Reconnection)

A "full picture" of the game state (used when starting the game, reconnecting, or for a global resync).

```json
{
  "mainID": 4,
  "subID": 1,
  "erreur": false,
  "data": {
    "state": { 
      // Full game state
    }
  }
}
```

### ⚡ SubID 2 : List of `eventType`

<table>
  <thead>
    <tr>
      <th>Category</th>
      <th>Event Type ( eventType )</th>
      <th>Trigger / Context</th>
      <th>Expected JSON Payload ( payload )</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Lobby (MainID = 2)</strong></td>
      <td><code>LOBBY_PLAYER_JOINED</code></td>
      <td>A player joined the lobby.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": LOBBY_PLAYER_JOINED,
    "payload": {
      "clientID": int,
      "username": "string"
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>LOBBY_PLAYER_LEFT</code></td>
      <td>Following the <code>LEAVE_LOBBY</code> client action.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": LOBBY_PLAYER_LEFT,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>GAME_STARTED</code></td>
      <td>Following the <code>START_GAME</code> client action by the host.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": GAME_STARTED,
    "payload": {
      "nombre_tour": int,
      "mapID": int,
      "moneyStart": int,
      "currentClientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Game Turn ( MainID = 3 )</strong></td>
      <td><code>TURN_CHANGED</code></td>
      <td>Following the <code>END_TURN</code> action or at game start.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": TURN_CHANGED,
    "payload": {
      "currentClientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>DICE_ROLLED</code></td>
      <td>Following the <code>ROLL_DICE</code> client action.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": DICE_ROLLED,
    "payload": {
      "clientID": int,
      "dice1": int,
      "dice2": int,
      "card": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>PROPERTY_BOUGHT</code></td>
      <td>Following the <code>BUY_PROPERTY</code> client action.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": PROPERTY_BOUGHT,
    "payload": {
      "clientID": int,
      "propertyID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>HOUSE_BUILT</code></td>
      <td>A player built a house.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": HOUSE_BUILT,
    "payload": {
      "clientID": int,
      "propertyID": int,
      "totalHouses": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>GOT_OUT_OF_JAIL</code></td>
      <td>The player paid $50, used a card, or rolled a double.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": GOT_OUT_OF_JAIL,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>USE_CARD</code></td>
      <td>The player uses a card from their inventory.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": USE_CARD,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>END_TURN</code></td>
      <td>The end of a player's turn.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": END_TURN,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Auction ( MainID = 3 )</strong></td>
      <td><code>AUCTION_STARTED</code></td>
      <td>An auction has begun for a property.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": AUCTION_STARTED,
    "payload": {
      "propertyID": int,
      "startingPrice": int,
      "participants": [int]
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>PLACE_BID</code></td>
      <td>A player has placed a higher bid.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": PLACE_BID,
    "payload": {
      "clientID": int,
      "bidAmount": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>LEAVE_AUCTION</code></td>
      <td>A player has withdrawn from the auction.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": LEAVE_AUCTION,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>AUCTION_ENDED</code></td>
      <td>The auction has finished.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": AUCTION_ENDED,
    "payload": {
      "winnerID": int,
      "finalPrice": int,
      "propertyID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td><strong>Elimination & Game Conclusion</strong></td>
      <td><code>PLAYER_ELIMINATED</code></td>
      <td>A player has gone bankrupt and is out of the game.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": PLAYER_ELIMINATED,
    "payload": {
      "clientID": int
    }
  }
}</code></pre>
      </td>
    </tr>
    <tr>
      <td></td>
      <td><code>GAME_ENDED</code></td>
      <td>If the number of turns is reached or a player has no more money.</td>
      <td>
<pre><code>{
  "mainID": 4,
  "subID": 2,
  "erreur": false,
  "data": {
    "eventType": GAME_ENDED,
    "payload": {
      "winnerID": int,
      "classement": [
        {
          "rank": int,
          "clientID": int,
          "username": "string",
          "money": int,
          "netWorth": int
        }
      ]
    }
  }
}</code></pre>
        <p><i>Note: <code>netWorth</code> is calculated as: money + property purchase price + total cost of houses/hotels.</i></p>
      </td>
    </tr>
  </tbody>
</table>

-----

## 4\. Error Codes (Dictionary)

Codes that can be returned in the `"codeErreur"` field if a request fails (`erreur: true`).

| Category | Error Code | Explanation |
| --- | --- | --- |
| **General** | `BAD_JSON` | The sent JSON format is invalid or corrupted. |
|  | `VALIDATION_ERROR` | The sent data is incomplete or has the wrong type. |
|  | `UNKNOWN_MESSAGE` | The MainID or SubID is not recognized by the server. |
|  | `INTERNAL_ERROR` | Unexpected critical error on the server side. |
| **Authentication** | `AUTH_INVALID` | Incorrect username or password. |
|  | `AUTH_REQUIRED` | Action denied: user is not logged in. |
|  | `USERNAME_TAKEN` | Registration denied: username already exists. |
| **Lobby** | `LOBBY_NOT_FOUND` | The requested lobby does not exist (or no longer exists). |
|  | `LOBBY_FULL` | Cannot join: the lobby has reached its player limit. |
|  | `ALREADY_IN_LOBBY` | The player is already in a lobby. |
|  | `NOT_LOBBY_OWNER` | Action denied: only the lobby creator has this right. |
|  | `NOT_ENOUGH_PLAYERS` | Cannot start: not enough players in the lobby. |
| **Game** | `NOT_IN_GAME` | The player is not associated with any active game. |
|  | `NOT_YOUR_TURN` | Action denied: it is not this player's turn. |
|  | `INVALID_ACTION` | The requested action is not allowed in this context. |
|  | `INSUFFICIENT_FUNDS` | The player does not have enough money for this transaction. |
|  | `PROPERTY_NOT_FOR_SALE` | This property is already owned or cannot be bought. |
|  | `HOUSE_NOT_FOR_SALE` | Cannot buy another house. |
|  | `HOTEL_NOT_FOR_SALE` | Cannot buy a hotel. |
