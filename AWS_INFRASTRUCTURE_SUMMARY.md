# AWS Infrastructure Summary

This document provides a summary of the AWS infrastructure for the ChopperTracker application.

## Overall Architecture

The AWS environment is set up to host a web application with a backend service and a frontend website. The backend is designed to run as a containerized service in ECS, while the frontend is a static site hosted on S3 and served via CloudFront.

## Backend (ECS)

*   **ECS Cluster:** There is one ECS cluster named `flight-tracker-cluster`.
*   **ECS Service:** The cluster runs a service called `flight-tracker-backend`.
*   **Compute:** The service is configured to use Fargate Spot instances for cost-effective container execution.
*   **Load Balancing:** The service is connected to a load balancer to distribute traffic.
*   **Status:** **The backend service is not currently running.** The desired task count is zero, and the service has a history of health check failures, which indicates a problem with the application's stability.
*   **Task Definition:** The task definition for the service uses a Docker image from the ECR repository and is configured to connect to a Redis instance on ElastiCache.

## Frontend (S3 & CloudFront)

*   **S3 Bucket:** The frontend is hosted in an S3 bucket named `flight-tracker-web-ui-1750266711`, which is configured for static website hosting.
*   **CloudFront Distribution:** A CloudFront distribution is set up to serve the content from the S3 bucket.
*   **Domain:** The CloudFront distribution is configured with the domain names `choppertracker.com` and `www.choppertracker.com` and has a valid SSL certificate.

## AWS Organizations

*   **Organization:** This AWS account is the master account of an AWS Organization.
*   **Organization ID:** `o-wggbids2qn`
*   **Master Account ID:** `958933162000`
*   **Master Account Email:** `jeff@strout.us`
