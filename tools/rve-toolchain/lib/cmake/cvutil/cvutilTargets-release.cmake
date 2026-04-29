#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "cvutil::cvutil" for configuration "Release"
set_property(TARGET cvutil::cvutil APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(cvutil::cvutil PROPERTIES
  IMPORTED_IMPLIB_RELEASE "${_IMPORT_PREFIX}/lib/cvutil/cvutil.lib"
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "opencv_calib3d;opencv_core;opencv_dnn;opencv_features2d;opencv_flann;opencv_gapi;opencv_highgui;opencv_imgcodecs;opencv_imgproc;opencv_ml;opencv_objdetect;opencv_photo;opencv_stitching;opencv_video;opencv_videoio;opencv_alphamat;opencv_aruco;opencv_bgsegm;opencv_ccalib;opencv_cvv;opencv_datasets;opencv_dnn_objdetect;opencv_dnn_superres;opencv_dpm;opencv_face;opencv_freetype;opencv_fuzzy;opencv_hdf;opencv_hfs;opencv_img_hash;opencv_intensity_transform;opencv_line_descriptor;opencv_mcc;opencv_optflow;opencv_phase_unwrapping;opencv_plot;opencv_quality;opencv_rapid;opencv_reg;opencv_rgbd;opencv_saliency;opencv_shape;opencv_signal;opencv_stereo;opencv_structured_light;opencv_superres;opencv_surface_matching;opencv_text;opencv_tracking;opencv_videostab;opencv_wechat_qrcode;opencv_xfeatures2d;opencv_ximgproc;opencv_xobjdetect;opencv_xphoto;Qt6::Core;Qt6::Widgets;Qt6::Charts;Qt6::Gui;Qt6::OpenGL;cvutil::PluginManager;cvutil::RoiManager"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/cvutil.dll"
  )

list(APPEND _cmake_import_check_targets cvutil::cvutil )
list(APPEND _cmake_import_check_files_for_cvutil::cvutil "${_IMPORT_PREFIX}/lib/cvutil/cvutil.lib" "${_IMPORT_PREFIX}/bin/cvutil.dll" )

# Import target "cvutil::PluginManager" for configuration "Release"
set_property(TARGET cvutil::PluginManager APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(cvutil::PluginManager PROPERTIES
  IMPORTED_IMPLIB_RELEASE "${_IMPORT_PREFIX}/lib/cvutil/PluginManager.lib"
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "Qt6::Core;Qt6::Widgets;Qt6::Charts;Qt6::Gui;Qt6::OpenGL"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/PluginManager.dll"
  )

list(APPEND _cmake_import_check_targets cvutil::PluginManager )
list(APPEND _cmake_import_check_files_for_cvutil::PluginManager "${_IMPORT_PREFIX}/lib/cvutil/PluginManager.lib" "${_IMPORT_PREFIX}/bin/PluginManager.dll" )

# Import target "cvutil::RoiManager" for configuration "Release"
set_property(TARGET cvutil::RoiManager APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(cvutil::RoiManager PROPERTIES
  IMPORTED_IMPLIB_RELEASE "${_IMPORT_PREFIX}/lib/cvutil/RoiManager.lib"
  IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "opencv_calib3d;opencv_core;opencv_dnn;opencv_features2d;opencv_flann;opencv_gapi;opencv_highgui;opencv_imgcodecs;opencv_imgproc;opencv_ml;opencv_objdetect;opencv_photo;opencv_stitching;opencv_video;opencv_videoio;opencv_alphamat;opencv_aruco;opencv_bgsegm;opencv_ccalib;opencv_cvv;opencv_datasets;opencv_dnn_objdetect;opencv_dnn_superres;opencv_dpm;opencv_face;opencv_freetype;opencv_fuzzy;opencv_hdf;opencv_hfs;opencv_img_hash;opencv_intensity_transform;opencv_line_descriptor;opencv_mcc;opencv_optflow;opencv_phase_unwrapping;opencv_plot;opencv_quality;opencv_rapid;opencv_reg;opencv_rgbd;opencv_saliency;opencv_shape;opencv_signal;opencv_stereo;opencv_structured_light;opencv_superres;opencv_surface_matching;opencv_text;opencv_tracking;opencv_videostab;opencv_wechat_qrcode;opencv_xfeatures2d;opencv_ximgproc;opencv_xobjdetect;opencv_xphoto;Qt6::Core;Qt6::Widgets;Qt6::Charts;Qt6::Gui;Qt6::OpenGL"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/bin/RoiManager.dll"
  )

list(APPEND _cmake_import_check_targets cvutil::RoiManager )
list(APPEND _cmake_import_check_files_for_cvutil::RoiManager "${_IMPORT_PREFIX}/lib/cvutil/RoiManager.lib" "${_IMPORT_PREFIX}/bin/RoiManager.dll" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
