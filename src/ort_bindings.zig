const std = @import("std");
const c = @cImport({
    @cInclude("onnxruntime_c_api.h");
});

pub const OrtEnv = opaque {};
pub const OrtSession = opaque {};
pub const OrtMemoryInfo = opaque {};
pub const OrtValue = opaque {};
pub const OrtAllocator = opaque {};
pub const OrtIoBinding = opaque {};
pub const OrtRunOptions = opaque {};

pub const OrtApi = extern struct {
    CreateEnv: fn (log_severity_level: c_int, logid: [*c]const u8, out: **OrtEnv) callconv(.C) *c.OrtStatus,
    CreateSession: fn (env: *OrtEnv, model_path: [*c]const u8, options: *c.OrtSessionOptions, out: **OrtSession) callconv(.C) *c.OrtStatus,
    CreateTensorWithDataAsOrtValue: fn (info: *OrtMemoryInfo, p_data: ?*anyopaque, p_data_len: usize, shape: [*]const i64, shape_len: usize, type: c_int, out: **OrtValue) callconv(.C) *c.OrtStatus,
    GetTensorMutableData: fn (value: *OrtValue, out: *?*anyopaque) callconv(.C) *c.OrtStatus,
    RunWithBinding: fn (session: *OrtSession, run_options: ?*OrtRunOptions, binding: *OrtIoBinding) callconv(.C) *c.OrtStatus,
    CreateIoBinding: fn (session: *OrtSession, out: **OrtIoBinding) callconv(.C) *c.OrtStatus,
    BindInput: fn (binding: *OrtIoBinding, name: [*:0]const u8, value: *OrtValue) callconv(.C) *c.OrtStatus,
    BindOutput: fn (binding: *OrtIoBinding, name: [*:0]const u8, value: *OrtValue) callconv(.C) *c.OrtStatus,
    GetAllocatorWithDefaultOptions: fn (out: **OrtAllocator) callconv(.C) *c.OrtStatus,
    AllocatorFree: fn (allocator: *OrtAllocator, ptr: ?*anyopaque) callconv(.C) void,
    // Add other necessary functions here
};

pub fn getOrtApi() *const OrtApi {
    return @as(*const OrtApi, @ptrCast(c.OrtGetApiBase().?.GetApi.?(c.ORT_API_VERSION)));
}

pub const OrtError = error{
    EnvCreationFailed,
    SessionCreationFailed,
    TensorCreationFailed,
    RunFailed,
    BindingCreationFailed,
    BindingFailed,
    AllocatorError,
    GetTensorDataFailed,
};

pub fn createOrtEnv(log_severity_level: c_int, logid: [*:0]const u8) !*OrtEnv {
    var env: *OrtEnv = undefined;
    const status = getOrtApi().CreateEnv(log_severity_level, logid, &env);
    if (status != null) {
        return OrtError.EnvCreationFailed;
    }
    return env;
}

pub fn createOrtSession(env: *OrtEnv, model_path: [*:0]const u8) !*OrtSession {
    var session: *OrtSession = undefined;
    const status = getOrtApi().CreateSession(env, model_path, null, &session);
    if (status != null) {
        return OrtError.SessionCreationFailed;
    }
    return session;
}

pub fn createTensorWithData(comptime T: type, info: *OrtMemoryInfo, data: []const T, shape: []const i64) !*OrtValue {
    var tensor: *OrtValue = undefined;
    const status = getOrtApi().CreateTensorWithDataAsOrtValue(info, @as(?*anyopaque, @ptrCast(data.ptr)), data.len * @sizeOf(T), shape.ptr, shape.len, switch (T) {
        f32 => c.ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
        i32 => c.ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32,
        // Add more type mappings as needed
        else => @compileError("Unsupported tensor data type"),
    }, &tensor);
    if (status != null) {
        return OrtError.TensorCreationFailed;
    }
    return tensor;
}

pub fn getTensorMutableData(comptime T: type, value: *OrtValue) ![]T {
    var data: ?*anyopaque = undefined;
    const status = getOrtApi().GetTensorMutableData(value, &data);
    if (status != null) {
        return OrtError.GetTensorDataFailed;
    }
    // Note: This assumes you know the size of the tensor. In a real implementation,
    // you might want to get the tensor shape and calculate the size.
    return @as([*]T, @ptrCast(@alignCast(data.?)))[0..1];
}

pub fn createIoBinding(session: *OrtSession) !*OrtIoBinding {
    var binding: *OrtIoBinding = undefined;
    const status = getOrtApi().CreateIoBinding(session, &binding);
    if (status != null) {
        return OrtError.BindingCreationFailed;
    }
    return binding;
}

pub fn bindInput(binding: *OrtIoBinding, name: [*:0]const u8, value: *OrtValue) !void {
    const status = getOrtApi().BindInput(binding, name, value);
    if (status != null) {
        return OrtError.BindingFailed;
    }
}

pub fn bindOutput(binding: *OrtIoBinding, name: [*:0]const u8, value: *OrtValue) !void {
    const status = getOrtApi().BindOutput(binding, name, value);
    if (status != null) {
        return OrtError.BindingFailed;
    }
}

pub fn runWithBinding(session: *OrtSession, run_options: ?*OrtRunOptions, binding: *OrtIoBinding) !void {
    const status = getOrtApi().RunWithBinding(session, run_options, binding);
    if (status != null) {
        return OrtError.RunFailed;
    }
}

pub fn getAllocatorWithDefaultOptions() !*OrtAllocator {
    var allocator: *OrtAllocator = undefined;
    const status = getOrtApi().GetAllocatorWithDefaultOptions(&allocator);
    if (status != null) {
        return OrtError.AllocatorError;
    }
    return allocator;
}

pub fn allocatorFree(allocator: *OrtAllocator, ptr: ?*anyopaque) void {
    getOrtApi().AllocatorFree(allocator, ptr);
}
