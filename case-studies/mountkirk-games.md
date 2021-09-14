# Case Study: Mountkirk Games

The case study can be found [here](https://services.google.com/fh/files/blogs/master_case_study_mountkirk_games.pdf).

Makes online, session-based, multiplayer games for mobile platforms. Starting to expand to other platforms after successfully migrating their on-premises environments to Google Cloud.

Their first endevour is to create a retro-style first-person shooter (FPS) game that allows hundreds of simultaneous players to join a geo-specific digital areana from multiple platforms and locations. A real-time digital banner will display a global leaderboard of all the top players across every active arena.

## Solution Concept

Mountkirk Games is building a new multiplayer game that they expect to be very popular. They plan to deploy the game’s backend on Google Kubernetes Engine so they can scale rapidly and use Google’s global load balancer to route players to the closest regional game arenas. In order to keep the global leader board in sync, they plan to use a multi-region Spanner cluster. 

## Existing Technical Environment

The existing environment was recently migrated to Google Cloud, and five games came across using lift-and-shift virtual machine migrations, with a few minor exceptions. 

Each new game exists in an isolated Google Cloud project nested below a folder that maintains most of the permissions and network policies. Legacy games with low traffic have been consolidated into a single project. There are also separate environments for development and testing.

## Business Requirements

* Support multiple gaming platforms.
* Support multiple regions.
* Support rapid iteration of game features.
* Minimize latency.
* Optimize for dynamic scaling.
* Use managed services and pooled resources.
* Minimize costs.

## Technical Requirements

* Dynamically scale based on game activity.
* Publish scoring data on a near real–time global leaderboard.
* Store game activity logs in structured files for future analysis.
* Use GPU processing to render graphics server-side for multi-platform support.
* Support eventual migration of legacy games to this new platform


## Executive Summary

Our new game is our most ambitious to date and will open up doors for us to support more gaming platforms beyond mobile. Latency is our top priority, although cost management is the next most important challenge. As with our first cloud-based game, we have grown to expect the cloud to enable advanced analytics capabilities so we can rapidly iterate on our deployments of bug fixes and new functionality.

## My Thoughts

> Cloud Spanner

* Game Database layer
* globally consistent database that can keep inventory or match history for massive player populations anywhere.
* Can be used to house game state data, player authentication data, and inventory data.

> BigTable

* Logging events to bigtable

> Firestore

* NoSQL document database. 
* Scale to billions of documents with hierarchical user and world state data, all retrievable with very low latency.

> Cloud Storage

* Because storage rates for infrequently accessed data automatically decrease, you can keep long-term events and use them to train machine learning models on AI Platform.

> GKE

* Used to run dedicate game servers.
* Scale up and down the infrastructure
* Quick roll backs
* Containers are ephemeral



## Diagrams

[Overview of Gaming Infrastructure](https://cloud.google.com/architecture/cloud-game-infrastructure?hl=en)
![](https://cloud.google.com/architecture/images/game-cloud-infrastructure.svg)

[GCP Gaming Reference Architecture](https://cloud.google.com/architecture/images/best-practices-mobile-game-architecture-reference.svg)
![](https://cloud.google.com/architecture/images/best-practices-mobile-game-architecture-reference.svg)

[Backend Gaming Databases](https://cloud.google.com/architecture/gaming-backend-databases?hl=en)
![](https://cloud.google.com/architecture/images/gaming-backend-databases.png)

[GKE as dedicated game servers](https://cloud.google.com/architecture/images/running-dedicated-game-servers-architecture.svg)
![](https://cloud.google.com/architecture/images/running-dedicated-game-servers-architecture.svg)