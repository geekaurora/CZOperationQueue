# CZOperationQueue

Rewritten custom OperationQueue with GCD - DispatchQueue (Without using NSOperationQueue).

## Functionality

- Concurrent operations
- Operation priority
- Operation dependencies
- `maxConcurrentOperationCount`


### How gateKeeperQueue/jobQueue limits maxConcurrentOperationCount?
<img src="./Diagrams/DispatchQueue-limitMax-Semaphore.png" width="650">





