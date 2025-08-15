# ReadyPing System Diagrams and Flowcharts

## 1. System Architecture Overview

```mermaid
graph TB
    subgraph "Frontend Applications"
        CA[Customer App<br/>ReadyPing<br/>Port: 8081]
        RA[Restaurant App<br/>ReadyPingPlus<br/>Port: 8082]
    end
    
    subgraph "Backend Infrastructure"
        API[API Server<br/>Node.js/Express<br/>Port: 3000]
        DB[(MongoDB<br/>Database)]
        WS[WebSocket<br/>Server]
    end
    
    subgraph "External Services"
        WA[WhatsApp Business<br/>API - Twilio]
        QR[QR Code<br/>Generation]
    end
    
    CA <--> API
    RA <--> API
    API <--> DB
    API <--> WS
    WS <--> CA
    WS <--> RA
    API <--> WA
    API <--> QR
    
    style CA fill:#e1f5fe
    style RA fill:#f3e5f5
    style API fill:#e8f5e8
    style DB fill:#fff3e0
    style WA fill:#fce4ec
    style QR fill:#f1f8e9
```

## 2. Frontend Architecture Pattern

```mermaid
graph LR
    subgraph "UI Layer"
        S[Screens<br/>User Interface]
    end
    
    subgraph "Provider Layer"
        AP[AuthProvider<br/>Authentication State]
        OP[OrderProvider<br/>Order Management]
        RP[RestaurantProvider<br/>Restaurant Data]
    end
    
    subgraph "Service Layer"
        AS[ApiService<br/>HTTP Communication]
        LS[LocalStorage<br/>SharedPreferences]
    end
    
    S <--> AP
    S <--> OP
    S <--> RP
    AP <--> AS
    OP <--> AS
    RP <--> AS
    AP <--> LS
    OP <--> LS
    
    style S fill:#e3f2fd
    style AP fill:#f3e5f5
    style OP fill:#e8f5e8
    style RP fill:#fff3e0
    style AS fill:#fce4ec
    style LS fill:#f1f8e9
```

## 3. Backend Layered Architecture

```mermaid
graph TB
    subgraph "Routes Layer"
        AR[Auth Routes<br/>POST /login, /register]
        OR[Order Routes<br/>GET, POST, PUT /orders]
        QR[QR Routes<br/>GET, POST /qr]
    end
    
    subgraph "Controller Layer"
        AC[Auth Controller<br/>Business Logic]
        OC[Order Controller<br/>Order Processing]
        QC[QR Controller<br/>QR Generation]
    end
    
    subgraph "Service Layer"
        WS[WhatsApp Service<br/>Notification Delivery]
        ES[Email Service<br/>Future Implementation]
        PS[Payment Service<br/>Future Implementation]
    end
    
    subgraph "Model Layer"
        UM[User Model<br/>Mongoose Schema]
        OM[Order Model<br/>Mongoose Schema]
        QM[QR Model<br/>Mongoose Schema]
    end
    
    subgraph "Middleware Layer"
        AM[Auth Middleware<br/>JWT Validation]
        VM[Validation Middleware<br/>Request Validation]
        EM[Error Middleware<br/>Error Handling]
    end
    
    AR --> AC
    OR --> OC
    QR --> QC
    AC --> WS
    OC --> WS
    QC --> QR
    AC --> UM
    OC --> OM
    QC --> QM
    AM --> AR
    VM --> AR
    EM --> AR
    
    style AR fill:#e1f5fe
    style AC fill:#f3e5f5
    style WS fill:#e8f5e8
    style UM fill:#fff3e0
    style AM fill:#fce4ec
```

## 4. Order Processing Flowchart

```mermaid
flowchart TD
    Start([Customer Opens App]) --> Login{Login Required?}
    Login -->|Yes| Auth[Enter Phone + Password]
    Login -->|No| Discover[Discover Tab]
    Auth --> Discover
    
    Discover --> Choice{How to Find Restaurant?}
    Choice -->|QR Scan| QRScan[Scan QR Code]
    Choice -->|Search| Search[Search Restaurant Name]
    
    QRScan --> Menu[Restaurant Menu Displayed]
    Search --> Menu
    
    Menu --> Browse[Browse Menu Items]
    Browse --> Add[Add Items to Cart]
    Add --> More{Add More Items?}
    More -->|Yes| Browse
    More -->|No| Checkout[Proceed to Checkout]
    
    Checkout --> Payment[Payment Processing]
    Payment --> PlaceOrder[Place Order]
    PlaceOrder --> Backend[Order Sent to Backend]
    
    Backend --> Restaurant[Order Appears in Restaurant App]
    Restaurant --> Prepare[Restaurant Prepares Food]
    Prepare --> Ready{Food Ready?}
    Ready -->|No| Prepare
    Ready -->|Yes| MarkReady[Mark Order as Ready]
    
    MarkReady --> Notify[Send WhatsApp Notification]
    Notify --> Customer[Customer Receives Notification]
    Customer --> Pickup[Customer Picks Up Food]
    Pickup --> Complete[Mark Order as Completed]
    Complete --> End([Order Complete])
    
    style Start fill:#e8f5e8
    style End fill:#e8f5e8
    style Notify fill:#fce4ec
    style Customer fill:#fce4ec
```

## 5. Authentication Flow

```mermaid
sequenceDiagram
    participant C as Customer App
    participant A as Auth API
    participant D as Database
    participant R as Restaurant App
    
    C->>A: POST /login (phone, password)
    A->>D: Validate Credentials
    D-->>A: User Data
    A->>A: Generate JWT Token
    A-->>C: Return Token + User Data
    
    C->>A: API Request with JWT
    A->>A: Validate JWT Token
    A-->>C: Protected Resource
    
    R->>A: POST /login (phone, password)
    A->>D: Validate Restaurant Credentials
    D-->>A: Restaurant Data
    A->>A: Generate JWT Token
    A-->>R: Return Token + Restaurant Data
```

## 6. Real-time Communication Flow

```mermaid
sequenceDiagram
    participant CA as Customer App
    participant WS as WebSocket Server
    participant RA as Restaurant App
    participant WA as WhatsApp API
    
    CA->>WS: Connect WebSocket
    RA->>WS: Connect WebSocket
    
    RA->>WS: Update Order Status (Ready)
    WS->>CA: Real-time Status Update
    WS->>WA: Send WhatsApp Notification
    WA-->>CA: WhatsApp Message Delivered
    
    CA->>WS: Order Status Acknowledged
    WS->>RA: Status Update Confirmed
```

## 7. Database Schema Design

```mermaid
erDiagram
    USERS {
        string _id PK
        string phoneNumber UK
        string restaurantName
        string userType
        object settings
        datetime createdAt
        datetime updatedAt
    }
    
    ORDERS {
        string _id PK
        string orderId UK
        string customerName
        string phoneNumber
        string restaurantId FK
        string status
        array items
        number totalAmount
        datetime createdAt
        datetime readyAt
        datetime completedAt
        boolean notificationSent
    }
    
    QRCODES {
        string _id PK
        string code UK
        string restaurantId FK
        object menuData
        string imageUrl
        datetime createdAt
        boolean isActive
    }
    
    USERS ||--o{ ORDERS : "restaurant manages"
    USERS ||--o{ QRCODES : "restaurant generates"
    ORDERS }o--|| USERS : "belongs to restaurant"
    QRCODES }o--|| USERS : "belongs to restaurant"
```

## 8. API Endpoints Structure

```mermaid
graph TB
    subgraph "Authentication Endpoints"
        A1[POST /api/auth/login]
        A2[POST /api/auth/register]
        A3[GET /api/auth/profile]
        A4[PUT /api/auth/profile]
        A5[POST /api/auth/logout]
    end
    
    subgraph "Order Management"
        O1[GET /api/orders]
        O2[POST /api/orders]
        O3[GET /api/orders/:id]
        O4[PUT /api/orders/:id]
        O5[DELETE /api/orders/:id]
        O6[PUT /api/orders/:id/status]
    end
    
    subgraph "QR Code Operations"
        Q1[GET /api/qr/:code]
        Q2[POST /api/qr/generate]
        Q3[GET /api/qr/:code/image]
    end
    
    subgraph "Analytics"
        AN1[GET /api/analytics/orders]
        AN2[GET /api/analytics/revenue]
        AN3[GET /api/analytics/customers]
    end
    
    style A1 fill:#e1f5fe
    style O1 fill:#f3e5f5
    style Q1 fill:#e8f5e8
    style AN1 fill:#fff3e0
```

## 9. Security Architecture

```mermaid
graph TB
    subgraph "Frontend Security"
        FS1[HTTPS Encryption]
        FS2[JWT Token Storage]
        FS3[Input Validation]
        FS4[Local Data Encryption]
    end
    
    subgraph "Backend Security"
        BS1[JWT Token Validation]
        BS2[Password Hashing - bcryptjs]
        BS3[Request Rate Limiting]
        BS4[SQL Injection Prevention]
        BS5[CORS Configuration]
    end
    
    subgraph "Database Security"
        DS1[Data Encryption at Rest]
        DS2[Access Control]
        DS3[Audit Logging]
        DS4[Backup Encryption]
    end
    
    subgraph "External Service Security"
        ES1[WhatsApp API Authentication]
        ES2[Twilio Credential Management]
        ES3[API Key Rotation]
    end
    
    FS1 --> BS1
    FS2 --> BS1
    FS3 --> BS3
    BS2 --> DS1
    BS1 --> ES1
    
    style FS1 fill:#e8f5e8
    style BS1 fill:#fce4ec
    style DS1 fill:#fff3e0
    style ES1 fill:#f3e5f5
```

## 10. Deployment Architecture

```mermaid
graph TB
    subgraph "Frontend Deployment"
        FD1[Flutter Web Build]
        FD2[Netlify/Firebase Hosting]
        FD3[CDN Distribution]
        FD4[HTTPS Certificate]
    end
    
    subgraph "Backend Deployment"
        BD1[Node.js Server]
        BD2[Load Balancer]
        BD3[Multiple Instances]
        BD4[Auto Scaling]
    end
    
    subgraph "Database Deployment"
        DD1[MongoDB Atlas]
        DD2[Database Clustering]
        DD3[Backup Strategy]
        DD4[Monitoring]
    end
    
    subgraph "External Services"
        ED1[Twilio WhatsApp API]
        ED2[Payment Gateway]
        ED3[Email Service]
    end
    
    FD1 --> FD2
    FD2 --> FD3
    BD1 --> BD2
    BD2 --> BD3
    BD3 --> DD1
    BD1 --> ED1
    
    style FD1 fill:#e1f5fe
    style BD1 fill:#f3e5f5
    style DD1 fill:#e8f5e8
    style ED1 fill:#fff3e0
```

---

*These diagrams provide comprehensive visual representation of the ReadyPing system architecture, data flow, and technical implementation suitable for academic research papers and technical documentation.* 