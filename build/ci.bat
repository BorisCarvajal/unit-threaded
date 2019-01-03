@echo off
@setlocal


echo Unit Tests
pushd %~dp0\..

echo ""
echo Regular tests
dub test -q --build=unittest-cov
echo Unthreaded tests
dub run -q -c unittest-unthreaded --build=unittest-cov
echo Light tests
dub run -q -c unittest-light --build=unittest

popd


echo ""
echo Integration tests
echo ""

echo Issue 61
pushd %~dp0\..\tests\integration_tests\issue61
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

echo Issue 109
pushd %~dp0\..\tests\integration_tests\issue109
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

echo Issue 116
pushd %~dp0\..\tests\integration_tests\issue116
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd

echo runTestsMain
pushd %~dp0\..\tests\integration_tests\runTestsMain
dub run --build=unittest
if %errorlevel% neq 0 exit /b %errorlevel%
popd