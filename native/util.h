#pragma once


#include <napi.h>
#include <string>
#include <vector>
#include <string>
#include <codecvt>
#include <locale>
#include <functional>
#include <map>
#include <assert.h>
#include <unordered_map>
#include <list>

using std::string;
using std::vector;
using std::wstring;

typedef unsigned char byte;

//state storage per context
struct PluginInstance {};

enum class CaptureMode {
	//Capture the desktop pixels relative to target window
	Desktop = 0,
	//Capture the window front buffer directly, before os scaling is applied
	Window = 1,
	//Capture the opengl front buffer directly from the rs client process, this mode is much more complicated and only works on windows right now
	OpenGL = 2
};

struct JSRectangle {
	int x;
	int y;
	int width;
	int height;
	JSRectangle() = default;
	JSRectangle(int x, int y, int w, int h) :x(x), y(y), width(w), height(h) {}
	Napi::Object ToJs(Napi::Env env) const {
		auto ret = Napi::Object::New(env);
		ret.Set("x", x);
		ret.Set("y", y);
		ret.Set("width", width);
		ret.Set("height", height);
		return ret;
	}
	static JSRectangle FromJsValue(const Napi::Value& val) {
		auto rect = val.As<Napi::Object>();
		int x = rect.Get("x").As<Napi::Number>().Int32Value();
		int y = rect.Get("y").As<Napi::Number>().Int32Value();
		int w = rect.Get("width").As<Napi::Number>().Int32Value();
		int h = rect.Get("height").As<Napi::Number>().Int32Value();
		return JSRectangle(x, y, w, h);
	}
};

struct JSPoint {
	int x;
	int y;
	JSPoint() = default;
	JSPoint(int x, int y) :x(x), y(y) {}
	Napi::Object ToJs(Napi::Env env) const {
		auto ret = Napi::Object::New(env);
		ret.Set("x", x);
		ret.Set("y", y);
		return ret;
	}
};

void fillImageOpaque(void* data, size_t len);
void flipBGRAtoRGBA(void* data, size_t len);
void flipBGRAtoRGBA(void* outdata, void* indata, size_t len);
