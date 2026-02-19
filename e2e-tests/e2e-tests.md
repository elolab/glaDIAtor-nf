# E2E tests

## Quick test

Running **glaDIAtor-nf** on full data sets requires a lot of memory and hours of processing. While real data sets offer better validation of the workflow, their resource demands limit frequent use.

For development, a quick test can run the entire workflow without producing scientifically accurate results. Its purpose is to verify automation logic, catch installation issues, and detect obvious regressions.

Our quick test is using a subset of input data used in [the tutorial](https://elolab.github.io/glaDIAtor-nf). A procedure to select a valid subset of DIA spectra was developed by Balázs Bálint ([subset preparation](subset-preparation/subset-preparation.md)). In short, the workflow is run once on a full data set, a few top-scoring proteins are selected, and the scan windows that identified them are used to create a subset of full data set.

The subset is stored in [Seafile / \[glaDIAtor-nf\] Subset of example input spectra](https://seafile.utu.fi/library/931c97df-91fa-4f90-942d-40705ed284c0/%5BglaDIAtor-nf%5D%20Subset%20of%20example%20input%20spectra%20for%20quick%20test%20in%20GitLab) and downloaded during test execution using `wget`. If needed, the subset can be regenerated following the [subset preparation](subset-preparation/subset-preparation.md) procedure.

### Run on the host

The test can be executed on the host machine. It requires NextFlow and Apptainer

```sh
cd e2e-tests
./e2e-tests.sh
```

### Run with Docker

The test can be executed with Docker using _Dev Containers extension_ of VSCode. It requires Docker or Podman and VSCode

* Run command: _Dev Containers: Rebuild and Reopen in Container_.
* Execute the test
  ```sh
  cd e2e-tests
  ./e2e-tests.sh
  ```

Running E2E tests this way is very similar to what GitLab CI does.

## Long test

Manually go through the tutorial.

Some of the steps peak with memory consumption close to 16 GiB of RAM. The run takes 1-3 hours.

{bdg-warning}`pending` Automated, on-demand execution of the tutorial could be added.
