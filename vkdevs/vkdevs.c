/*
 * vkdevs.c - tiny Vulkan GPU probe used by play.
 *
 * Enumerates the physical devices the loader can see and prints one line per
 * device:
 *
 *   DEV <deviceName>|<type>|<major.minor>
 *
 * where type is one of: discrete, integrated, virtual, cpu, other.
 * It also prints a recommendation play uses to pick the GPU:
 *
 *   PICK <deviceName>|<major.minor>
 *
 * PICK prefers a discrete GPU and otherwise falls back to the first
 * non-CPU device, so the discrete GPU is favoured on any vendor's PRIME
 * setup (NVIDIA, AMD, ...). Nothing is printed if only software devices
 * (llvmpipe/SwiftShader) exist.
 *
 * Unlike `vulkaninfo --summary`, this never touches surfaces, so it works on
 * PRIME setups where the discrete GPU has no display attached.
 *
 * Compiled on first use (like fpslayer/) with only the Vulkan headers play
 * already needs.
 */
#include <stdio.h>
#include <string.h>

#include <vulkan/vulkan.h>

static const char *type_name(VkPhysicalDeviceType t) {
    switch (t) {
    case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU: return "discrete";
    case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU: return "integrated";
    case VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU: return "virtual";
    case VK_PHYSICAL_DEVICE_TYPE_CPU: return "cpu";
    default: return "other";
    }
}

static int is_software(const char *name) {
    return strstr(name, "llvmpipe") || strstr(name, "softpipe") ||
           strstr(name, "SwiftShader") || strstr(name, "lavapipe") ||
           strstr(name, "Mesa Off-screen");
}

int main(void) {
    VkApplicationInfo ai;
    memset(&ai, 0, sizeof ai);
    ai.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    ai.pApplicationName = "play-vkdevs";
    ai.apiVersion = VK_API_VERSION_1_0;

    VkInstanceCreateInfo ci;
    memset(&ci, 0, sizeof ci);
    ci.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ci.pApplicationInfo = &ai;

    VkInstance inst;
    if (vkCreateInstance(&ci, NULL, &inst) != VK_SUCCESS)
        return 1;

    uint32_t n = 0;
    if (vkEnumeratePhysicalDevices(inst, &n, NULL) != VK_SUCCESS) {
        vkDestroyInstance(inst, NULL);
        return 1;
    }
    if (n > 16)
        n = 16;
    VkPhysicalDevice devs[16];
    if (vkEnumeratePhysicalDevices(inst, &n, devs) != VK_SUCCESS) {
        vkDestroyInstance(inst, NULL);
        return 1;
    }

    int pick = -1;
    for (uint32_t i = 0; i < n; i++) {
        VkPhysicalDeviceProperties p;
        vkGetPhysicalDeviceProperties(devs[i], &p);
        printf("DEV %s|%s|%d.%d\n", p.deviceName, type_name(p.deviceType),
               VK_VERSION_MAJOR(p.apiVersion), VK_VERSION_MINOR(p.apiVersion));
        if (is_software(p.deviceName))
            continue;
        if (p.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU && pick < 0)
            pick = (int)i;
        if (pick < 0 && (p.deviceType == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU ||
                         p.deviceType == VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU))
            pick = (int)i;
    }

    if (pick >= 0) {
        VkPhysicalDeviceProperties p;
        vkGetPhysicalDeviceProperties(devs[pick], &p);
        printf("PICK %s|%d.%d\n", p.deviceName,
               VK_VERSION_MAJOR(p.apiVersion), VK_VERSION_MINOR(p.apiVersion));
    }

    vkDestroyInstance(inst, NULL);
    return 0;
}
