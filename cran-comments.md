## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local macOS, R 4.5.0
* GitHub Actions: macOS-latest (release), windows-latest (release),
  ubuntu-latest (devel, release, oldrel-1)

## Notes

The only NOTE is the standard "New submission" note. The package's optional
cross-validation tests against the 'intsvy' and 'segregation' packages are
guarded with `skip_if_not_installed()` and are exercised in continuous
integration.

## Downstream dependencies

There are currently no downstream dependencies (new package).
