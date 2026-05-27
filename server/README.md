## Monopoly 3D - C++ Server*

### Prerequisites

#### Network Access
To access the server or database, you must be connected to the **UFR Math-Info** network:
- **Off-campus:** Use the University VPN.
- **On-campus:** Connect via the `osiris` network or log in to a student machine (`ssh login@os-etudiant.u-strasbg.fr`).


#### Configuration

Before running the server, ensure you have a `.env` file in the root directory :
```
POSTGRES_DB=monopoly3d
POSTGRES_USER=monopoly
POSTGRES_PASSWORD=monopoly_l3S6
POSTGRES_PORT=5432

DB_HOST=db
DB_PORT=5432
DB_NAME=monopoly3d
DB_USER=monopoly
DB_PASSWORD=monopoly_l3S6
```

---

### Build and Run

We use Docker to ensure a consistent environment ( `Database` + `C++ Server` ).

1. **Switch to the development branch:**
   ```bash
   git checkout develop
   ```

2. **Build and start the containers:**
   ```bash
   docker compose up --build
   ```

---

### 🧹 Stopping and Cleaning Up

To stop the services, press `CTRL + C` in the terminal where Docker is running. 

To shut down the containers and **completely reset the database** (cleaning all volumes), run:
```bash
docker compose down -v
```
> **Warning:** The `-v` flag deletes the persistent database volume. Use it only if you want to re-run the initialization scripts (`00_schema.sql`, etc.).
