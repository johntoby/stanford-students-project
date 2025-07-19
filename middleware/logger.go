package middleware

import (
	"log"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

// Logger is a middleware that logs requests
func Logger() gin.HandlerFunc {
	// Set log level based on environment variable
	logLevel := os.Getenv("LOG_LEVEL")
	if logLevel == "" {
		logLevel = "info" // Default log level
	}

	return func(c *gin.Context) {
		// Start timer
		start := time.Now()

		// Process request
		c.Next()

		// Log request details
		latency := time.Since(start)
		statusCode := c.Writer.Status()
		clientIP := c.ClientIP()
		method := c.Request.Method
		path := c.Request.URL.Path

		// Log based on status code and log level
		switch {
		case statusCode >= 500:
			log.Printf("[ERROR] %s | %d | %s | %s %s | %s",
				clientIP, statusCode, latency, method, path, c.Errors.String())
		case statusCode >= 400:
			if logLevel != "error" {
				log.Printf("[WARN] %s | %d | %s | %s %s",
					clientIP, statusCode, latency, method, path)
			}
		default:
			if logLevel == "debug" || logLevel == "info" {
				log.Printf("[INFO] %s | %d | %s | %s %s",
					clientIP, statusCode, latency, method, path)
			}
		}
	}
}