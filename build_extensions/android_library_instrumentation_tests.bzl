"""A rule wrapper for an instrumentation test for an android library."""

load(
    "//build_extensions:generate_instrumentation_tests.bzl",
    "generate_instrumentation_tests",
)
load(
    "//build_extensions:infer_java_package_name.bzl",
    "infer_java_package_name",
)

def android_library_instrumentation_tests(name, srcs, deps, target_devices, manifest_values = {}, **kwargs):
    """A macro for an instrumentation test whose target under test is an android_library.

    Will generate a 'self-instrumentating' test binary and other associated rules

    The intent of this wrapper is to simplify the build API for creating instrumentation test rules
    for simple cases, while still supporting build_cleaner for automatic dependency management.

    This will generate:
      - an unused stub android_binary under test, to placate bazel
      - a test_lib android_library, containing all sources and dependencies
      - a test_binary android_binary (soon to be android_application)
      - the manifest to use for the test library.
      - for each device combination:
         - an android_instrumentation_test rule)

    Args:
      name: the name to use for the generated android_library rule. This is needed for build_cleaner to
        manage dependencies
      srcs: the test sources to generate rules for
      deps: the build dependencies to use for the generated test binary
      target_devices: array of device targets to execute on
      manifest_values: Optional. A dictionary of values to be overridden in the manifest
      **kwargs: arguments to pass to generated android_instrumentation_test rules
    """
    library_name = "%s_library" % name
    test_java_package_name = infer_java_package_name()

    native.android_binary(
        name = "target_stub_binary",
        manifest = "//build_extensions:AndroidManifest_target_stub.xml",
        # use the same package name as the test package, so it gets overridden
        manifest_values = {"applicationId": test_java_package_name},
        testonly = 1,
    )

    native.android_library(
        name = library_name,
        srcs = srcs,
        javacopts = kwargs.pop("javacopts", []),
        testonly = 1,
        deps = deps,
    )

    generate_instrumentation_tests(
        name = name,
        srcs = srcs,
        deps = [library_name],
        target_devices = target_devices,
        test_java_package_name = test_java_package_name,
        test_android_package_name = test_java_package_name,
        instrumentation_target_package = test_java_package_name,
        instruments = ":target_stub_binary",
        manifest_values = manifest_values,
        **kwargs
    )
