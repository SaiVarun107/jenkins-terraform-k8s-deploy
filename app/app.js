const express = require("express");

const app = express();
const PORT = 5000;

app.get("/", (req, res) => {
  res.send("Jenkins CI/CD Pipeline is Successful");
});

app.listen(PORT, "0.0.0.0", () => {
  console.log("Server started on port 5000");
});