
set(proj VTKv9)

# Set dependency list
set(${proj}_DEPENDENCIES "zlib")
if (Slicer_USE_PYTHONQT)
  list(APPEND ${proj}_DEPENDENCIES python)
endif()
if(Slicer_USE_TBB)
  list(APPEND ${proj}_DEPENDENCIES tbb)
endif()

# Include dependent projects if any
ExternalProject_Include_Dependencies(${proj} PROJECT_VAR proj DEPENDS_VAR ${proj}_DEPENDENCIES)

if(${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})
  unset(VTK_DIR CACHE)
  unset(VTK_SOURCE_DIR CACHE)
  find_package(VTK REQUIRED NO_MODULE)
endif()

# Sanity checks
if(DEFINED VTK_DIR AND NOT EXISTS ${VTK_DIR})
  message(FATAL_ERROR "VTK_DIR variable is defined but corresponds to nonexistent directory")
endif()

if(DEFINED VTK_SOURCE_DIR AND NOT EXISTS ${VTK_SOURCE_DIR})
  message(FATAL_ERROR "VTK_SOURCE_DIR variable is defined but corresponds to nonexistent directory")
endif()


if((NOT DEFINED VTK_DIR OR NOT DEFINED VTK_SOURCE_DIR) AND NOT ${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj})

  set(EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS)

  set(VTK_WRAP_PYTHON OFF)

  if(Slicer_USE_PYTHONQT)
    set(VTK_WRAP_PYTHON ON)
  endif()

  if(Slicer_USE_PYTHONQT)
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
      -DPYTHON_EXECUTABLE:PATH=${PYTHON_EXECUTABLE}
      -DPYTHON_INCLUDE_DIR:PATH=${PYTHON_INCLUDE_DIR}
      -DPYTHON_LIBRARY:FILEPATH=${PYTHON_LIBRARY}
      )
  endif()

  list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
    -DVTK_USE_GUISUPPORT:BOOL=ON
    -DVTK_USE_QVTK_QTOPENGL:BOOL=ON
    -DModule_vtkTestingRendering:BOOL=ON
    )
  if(Slicer_REQUIRED_QT_VERSION VERSION_LESS "5")
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
      -DVTK_QT_VERSION:STRING=4
      -DVTK_USE_QT:BOOL=ON
      -DQT_QMAKE_EXECUTABLE:FILEPATH=${QT_QMAKE_EXECUTABLE}
      )
  else()
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
      -DVTK_QT_VERSION:STRING=5
      -DVTK_Group_Qt:BOOL=ON
      -DQt5_DIR:FILEPATH=${Qt5_DIR}
      )
  endif()
  if("${Slicer_VTK_RENDERING_BACKEND}" STREQUAL "OpenGL2")
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
      -DModule_vtkGUISupportQtOpenGL:BOOL=ON
    )
  endif()
  if(Slicer_USE_TBB)
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
      -DTBB_INCLUDE_DIR:PATH=${TBB_INCLUDE_DIR}
      -DTBB_LIBRARY_DEBUG:FILEPATH=${TBB_LIBRARY_DEBUG}
      -DTBB_LIBRARY_RELEASE:FILEPATH=${TBB_LIBRARY_RELEASE}
      -DTBB_MALLOC_INCLUDE_DIR:PATH=${TBB_MALLOC_INCLUDE_DIR}
      -DTBB_MALLOC_LIBRARY_DEBUG:FILEPATH=${TBB_MALLOC_LIBRARY_DEBUG}
      -DTBB_MALLOC_LIBRARY_RELEASE:FILEPATH=${TBB_MALLOC_LIBRARY_RELEASE}
      -DTBB_MALLOC_PROXY_INCLUDE_DIR:PATH=${TBB_MALLOC_PROXY_INCLUDE_DIR}
      -DTBB_MALLOC_PROXY_LIBRARY_DEBUG:FILEPATH=${TBB_MALLOC_PROXY_LIBRARY_DEBUG}
      -DTBB_MALLOC_PROXY_LIBRARY_RELEASE:FILEPATH=${TBB_MALLOC_PROXY_LIBRARY_RELEASE}
      )
  endif()
  if(APPLE)
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
      -DVTK_USE_CARBON:BOOL=OFF
      -DVTK_USE_COCOA:BOOL=ON # Default to Cocoa, VTK/CMakeLists.txt will enable Carbon and disable cocoa if needed
      -DVTK_USE_X:BOOL=OFF
      -DVTK_REQUIRED_OBJCXX_FLAGS:STRING=
      #-DVTK_USE_RPATH:BOOL=ON # Unused
      )
  endif()
  if(UNIX AND NOT APPLE)
    find_package(FontConfig QUIET)
    if(FONTCONFIG_FOUND)
      list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
        -DModule_vtkRenderingFreeTypeFontConfig:BOOL=ON
        )
    endif()
  endif()

  # Disable Tk when Python wrapping is enabled
  if(Slicer_USE_PYTHONQT)
    list(APPEND EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS
      -DVTK_USE_TK:BOOL=OFF
      )
  endif()

  # Enable VTK_ENABLE_KITS only if CMake >= 3.0 is used
  set(VTK_ENABLE_KITS 0)
  if(CMAKE_MAJOR_VERSION EQUAL 3)
    set(VTK_ENABLE_KITS 1)
  endif()

  ExternalProject_SetIfNotDefined(
    ${CMAKE_PROJECT_NAME}_${proj}_GIT_REPOSITORY
    "${EP_GIT_PROTOCOL}://github.com/slicer/VTK.git"
    QUIET
    )

set(_git_tag)
if("${Slicer_VTK_VERSION_MAJOR}" STREQUAL "7")
  set(_git_tag "43f6ee36f6e28c8347768bd97df4d767da6b4ce7")
elseif("${Slicer_VTK_VERSION_MAJOR}" STREQUAL "9")
  set(_git_tag "10e8cdc30ea2b7dc4eca2c019073821c5750fb1f")
else()
  message(FATAL_ERROR "error: Unsupported Slicer_VTK_VERSION_MAJOR: ${Slicer_VTK_VERSION_MAJOR}")
endif()
  ExternalProject_SetIfNotDefined(
    ${CMAKE_PROJECT_NAME}_${proj}_GIT_TAG
    ${_git_tag}
    QUIET
    )

  set(EP_SOURCE_DIR ${CMAKE_BINARY_DIR}/${proj})
  set(EP_BINARY_DIR ${CMAKE_BINARY_DIR}/${proj}-build)

  ExternalProject_Add(${proj}
    ${${proj}_EP_ARGS}
    GIT_REPOSITORY "${${CMAKE_PROJECT_NAME}_${proj}_GIT_REPOSITORY}"
    GIT_TAG "${${CMAKE_PROJECT_NAME}_${proj}_GIT_TAG}"
    SOURCE_DIR ${EP_SOURCE_DIR}
    BINARY_DIR ${EP_BINARY_DIR}
    CMAKE_CACHE_ARGS
      -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
      -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
      -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
      -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
      -DCMAKE_CXX_STANDARD:STRING=${CMAKE_CXX_STANDARD}
      -DCMAKE_CXX_STANDARD_REQUIRED:BOOL=${CMAKE_CXX_STANDARD_REQUIRED}
      -DCMAKE_CXX_EXTENSIONS:BOOL=${CMAKE_CXX_EXTENSIONS}
      -DBUILD_TESTING:BOOL=OFF
      -DBUILD_EXAMPLES:BOOL=OFF
      -DBUILD_SHARED_LIBS:BOOL=ON
      -DVTK_USE_PARALLEL:BOOL=ON
      -DVTK_DEBUG_LEAKS:BOOL=${VTK_DEBUG_LEAKS}
      -DVTK_LEGACY_REMOVE:BOOL=ON
      -DVTK_WRAP_TCL:BOOL=OFF
      #-DVTK_USE_RPATH:BOOL=ON # Unused
      -DVTK_WRAP_PYTHON:BOOL=${VTK_WRAP_PYTHON}
      -DVTK_INSTALL_RUNTIME_DIR:PATH=${Slicer_INSTALL_BIN_DIR}
      -DVTK_INSTALL_LIBRARY_DIR:PATH=${Slicer_INSTALL_LIB_DIR}
      -DVTK_INSTALL_ARCHIVE_DIR:PATH=${Slicer_INSTALL_LIB_DIR}
      -DVTK_Group_Qt:BOOL=ON
      -DVTK_USE_SYSTEM_ZLIB:BOOL=ON
      -DZLIB_ROOT:PATH=${ZLIB_ROOT}
      -DZLIB_INCLUDE_DIR:PATH=${ZLIB_INCLUDE_DIR}
      -DZLIB_LIBRARY:FILEPATH=${ZLIB_LIBRARY}
      -DVTK_ENABLE_KITS:BOOL=${VTK_ENABLE_KITS}
      -DVTK_RENDERING_BACKEND:STRING=${Slicer_VTK_RENDERING_BACKEND}
      -DVTK_SMP_IMPLEMENTATION_TYPE:STRING=${Slicer_VTK_SMP_IMPLEMENTATION_TYPE}
      ${EXTERNAL_PROJECT_OPTIONAL_CMAKE_CACHE_ARGS}
    INSTALL_COMMAND ""
    DEPENDS
      ${${proj}_DEPENDENCIES}
    )

  ExternalProject_GenerateProjectDescription_Step(${proj})

  set(VTK_DIR ${EP_BINARY_DIR})
  set(VTK_SOURCE_DIR ${EP_SOURCE_DIR})

  if(NOT DEFINED VTK_VALGRIND_SUPPRESSIONS_FILE)
    set(VTK_VALGRIND_SUPPRESSIONS_FILE ${EP_SOURCE_DIR}/CMake/VTKValgrindSuppressions.supp)
  endif()
  mark_as_superbuild(VTK_VALGRIND_SUPPRESSIONS_FILE:FILEPATH)

  #-----------------------------------------------------------------------------
  # Launcher setting specific to build tree

  # library paths
  set(_library_output_subdir bin)
  if(UNIX)
    set(_library_output_subdir lib)
  endif()
  set(${proj}_LIBRARY_PATHS_LAUNCHER_BUILD ${VTK_DIR}/${_library_output_subdir}/<CMAKE_CFG_INTDIR>)
  mark_as_superbuild(
    VARS ${proj}_LIBRARY_PATHS_LAUNCHER_BUILD
    LABELS "LIBRARY_PATHS_LAUNCHER_BUILD"
    )

  # pythonpath
  if(Slicer_VTK_VERSION_MAJOR VERSION_GREATER 7)
    if(UNIX)
      set(${proj}_PYTHONPATH_LAUNCHER_BUILD
        ${VTK_DIR}/${_library_output_subdir}/python2.7/site-packages
        )
    else()
      set(${proj}_PYTHONPATH_LAUNCHER_BUILD
        ${VTK_DIR}/${_library_output_subdir}/<CMAKE_CFG_INTDIR>/Lib/site-packages
        )
    endif()
  else()
    set(${proj}_PYTHONPATH_LAUNCHER_BUILD
      ${VTK_DIR}/Wrapping/Python
      ${VTK_DIR}/${_library_output_subdir}/<CMAKE_CFG_INTDIR>
      )
  endif()

  mark_as_superbuild(
    VARS ${proj}_PYTHONPATH_LAUNCHER_BUILD
    LABELS "PYTHONPATH_LAUNCHER_BUILD"
    )

  #-----------------------------------------------------------------------------
  # Launcher setting specific to install tree

  # pythonpath
  if(NOT APPLE)
    # This is not required for macOS where VTK python package is installed
    # in a standard location using CMake/SlicerBlockInstallExternalPythonModules.cmake
    if(Slicer_VTK_VERSION_MAJOR VERSION_GREATER 8)
      if(UNIX)
        set(${proj}_PYTHONPATH_LAUNCHER_INSTALLED
          <APPLAUNCHER_DIR>/${Slicer_INSTALL_LIB_DIR}/python2.7/site-packages
          )
      else()
        set(${proj}_PYTHONPATH_LAUNCHER_INSTALLED
          <APPLAUNCHER_DIR>/${Slicer_INSTALL_BIN_DIR}/Lib/site-packages
          )
      endif()
    else()
      set(${proj}_PYTHONPATH_LAUNCHER_INSTALLED
        <APPLAUNCHER_DIR>/${Slicer_INSTALL_LIB_DIR}/python2.7/site-packages
        )
    endif()
    mark_as_superbuild(
      VARS ${proj}_PYTHONPATH_LAUNCHER_INSTALLED
      LABELS "PYTHONPATH_LAUNCHER_INSTALLED"
      )
  endif()

else()
  ExternalProject_Add_Empty(${proj} DEPENDS ${${proj}_DEPENDENCIES})
endif()

mark_as_superbuild(VTK_SOURCE_DIR:PATH)

mark_as_superbuild(
  VARS VTK_DIR:PATH
  LABELS "FIND_PACKAGE"
  )
