#ifndef VELOX_H
#define VELOX_H

#ifdef __cplusplus
#define VLX_EXTERNSTART extern "C" {
#define VLX_EXTERNEND }
#define VLX_EXTERN extern "C"
#else
#define VLX_EXTERNSTART
#define VLX_EXTERNEND
#define VLX_EXTERN
#endif

#endif /* VELOX_H */