import express from "express";
import dotenv from "dotenv";
import cookieParser from "cookie-parser";
import cors from "cors";
import mongoose from "mongoose";
import authRoutes from "./routes/authRoutes.js"
import machineRoutes from "./routes/machineRoutes.js"

dotenv.config();

const PORT = process.env.PORT || 5000;
const app = express();


console.log("Starting server...");
console.log("Environment:", process.env.NODE_ENV || "development");


app.use(cookieParser());
app.use(express.json());

app.use(
  cors({
    origin: "*",
    credentials: true,
  })
);


app.get("/health", (req, res) => {
  const dbState = mongoose.connection.readyState;
  const dbStatusMap = {
    0: "disconnected",
    1: "connected",
    2: "connecting",
    3: "disconnecting",
  };

  res.status(200).json({
    status: "ok",
    serverTime: new Date().toISOString(),
    database: dbStatusMap[dbState] || "unknown",
  });
});

app.use("/API/auth", authRoutes);
app.use("/API/machines", machineRoutes);


mongoose
  .connect(process.env.MONGODB_CONN, { dbName: "LimeLIghtIt" })
  .then(() => {
    console.log("✅ Database connected successfully");
  })
  .catch((err) => {
    console.error("❌ Database connection failed:", err.message);
  });


app.use((err, req, res, next) => {
  console.error("🔥 ERROR:", {
    message: err.message,
    stack: err.stack,
    path: req.originalUrl,
    method: req.method,
  });

  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || "Internal server error",
  });
});


app.listen(PORT, () => {
  console.log(`✅ Server running on port ${PORT}`);
});
