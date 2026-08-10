/*
 * play_fps.c - minimal Vulkan layer that counts presented frames and
 * writes the current FPS to a file (default /tmp/play/fps.txt).
 *
 * Used by `play <game> hud` as an independent FPS source (no MangoHud).
 * Enabled with: VK_LAYER_PATH=<dir> VK_INSTANCE_LAYERS=VK_LAYER_PLAY_fps
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdatomic.h>
#include <time.h>
#include <pthread.h>
#include <unistd.h>

#include <vulkan/vulkan.h>
#include <vulkan/vk_layer.h>

#ifndef VK_LAYER_EXPORT
#define VK_LAYER_EXPORT __attribute__((visibility("default")))
#endif

#define MAX_DEVICES 16

static PFN_vkGetInstanceProcAddr g_next_gipa = NULL;

static _Atomic uint64_t g_presents = 0;
static _Atomic int g_writer_running = 0;

typedef struct DevNode {
    void *key; /* loader dispatch-table pointer shared by device + queues */
    PFN_vkGetDeviceProcAddr gdpa;
    PFN_vkQueuePresentKHR present;
} DevNode;

static DevNode g_nodes[MAX_DEVICES];
static int g_nnodes = 0;
static pthread_mutex_t g_mutex = PTHREAD_MUTEX_INITIALIZER;

static double now_s(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

static void *writer_thread(void *arg) {
    (void)arg;
    const char *file = getenv("PLAY_FPS_FILE");
    if (!file || !*file)
        file = "/tmp/play/fps.txt";
    uint64_t last = 0;
    double last_t = now_s();
    char buf[32];
    for (;;) {
        usleep(200 * 1000);
        double t = now_s();
        uint64_t c = atomic_load_explicit(&g_presents, memory_order_relaxed);
        double dt = t - last_t;
        double fps = dt > 0.001 ? (double)(c - last) / dt : 0.0;
        last = c;
        last_t = t;
        int n = snprintf(buf, sizeof buf, "%d\n", (int)(fps + 0.5));
        FILE *f = fopen(file, "w");
        if (f) {
            fwrite(buf, 1, (size_t)n, f);
            fclose(f);
        }
    }
    return NULL;
}

static void start_writer(void) {
    if (!atomic_exchange_explicit(&g_writer_running, 1, memory_order_relaxed)) {
        pthread_t th;
        pthread_create(&th, NULL, writer_thread, NULL);
        pthread_detach(th);
    }
}

static void *key_of(void *handle) {
    return handle ? *(void **)handle : NULL;
}

static DevNode *find_node(void *key) {
    for (int i = 0; i < g_nnodes; i++)
        if (g_nodes[i].key == key)
            return &g_nodes[i];
    return NULL;
}

static DevNode *find_or_add(void *key) {
    pthread_mutex_lock(&g_mutex);
    DevNode *n = find_node(key);
    if (!n && g_nnodes < MAX_DEVICES) {
        n = &g_nodes[g_nnodes++];
        memset(n, 0, sizeof *n);
        n->key = key;
    }
    pthread_mutex_unlock(&g_mutex);
    return n;
}

static VKAPI_ATTR VkResult VKAPI_CALL
play_fps_CreateInstance(const VkInstanceCreateInfo *pCreateInfo,
                        const VkAllocationCallbacks *pAllocator,
                        VkInstance *pInstance) {
    VkLayerInstanceCreateInfo *lci = (VkLayerInstanceCreateInfo *)pCreateInfo->pNext;
    while (lci && (lci->sType != VK_STRUCTURE_TYPE_LOADER_INSTANCE_CREATE_INFO ||
                   lci->function != VK_LAYER_LINK_INFO))
        lci = (VkLayerInstanceCreateInfo *)lci->pNext;
    if (!lci || !lci->u.pLayerInfo)
        return VK_ERROR_INITIALIZATION_FAILED;
    g_next_gipa = lci->u.pLayerInfo->pfnNextGetInstanceProcAddr;
    lci->u.pLayerInfo = lci->u.pLayerInfo->pNext;
    PFN_vkCreateInstance create = (PFN_vkCreateInstance)g_next_gipa(VK_NULL_HANDLE, "vkCreateInstance");
    return create(pCreateInfo, pAllocator, pInstance);
}

static VKAPI_ATTR VkResult VKAPI_CALL
play_fps_CreateDevice(VkPhysicalDevice physicalDevice,
                      const VkDeviceCreateInfo *pCreateInfo,
                      const VkAllocationCallbacks *pAllocator,
                      VkDevice *pDevice) {
    VkLayerDeviceCreateInfo *lci = (VkLayerDeviceCreateInfo *)pCreateInfo->pNext;
    while (lci && (lci->sType != VK_STRUCTURE_TYPE_LOADER_DEVICE_CREATE_INFO ||
                   lci->function != VK_LAYER_LINK_INFO))
        lci = (VkLayerDeviceCreateInfo *)lci->pNext;
    if (!lci || !lci->u.pLayerInfo)
        return VK_ERROR_INITIALIZATION_FAILED;
    PFN_vkGetInstanceProcAddr next_gipa = lci->u.pLayerInfo->pfnNextGetInstanceProcAddr;
    PFN_vkGetDeviceProcAddr next_gdpa = lci->u.pLayerInfo->pfnNextGetDeviceProcAddr;
    lci->u.pLayerInfo = lci->u.pLayerInfo->pNext;
    PFN_vkCreateDevice create = (PFN_vkCreateDevice)next_gipa(VK_NULL_HANDLE, "vkCreateDevice");
    VkResult res = create(physicalDevice, pCreateInfo, pAllocator, pDevice);
    if (res != VK_SUCCESS)
        return res;
    DevNode *n = find_or_add(key_of(*pDevice));
    if (n) {
        n->gdpa = next_gdpa;
        n->present = (PFN_vkQueuePresentKHR)next_gdpa(*pDevice, "vkQueuePresentKHR");
    }
    start_writer();
    return res;
}

static VKAPI_ATTR VkResult VKAPI_CALL
play_fps_PresentKHR(VkQueue queue, const VkPresentInfoKHR *pPresentInfo) {
    DevNode *n = NULL;
    pthread_mutex_lock(&g_mutex);
    n = find_node(key_of(queue));
    pthread_mutex_unlock(&g_mutex);
    VkResult res;
    if (n && n->present)
        res = n->present(queue, pPresentInfo);
    else
        res = VK_ERROR_DEVICE_LOST;
    if (res == VK_SUCCESS || res == VK_SUBOPTIMAL_KHR)
        atomic_fetch_add_explicit(&g_presents, 1, memory_order_relaxed);
    return res;
}

VK_LAYER_EXPORT VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
vkGetInstanceProcAddr(VkInstance instance, const char *pName) {
    if (!pName)
        return NULL;
    if (strcmp(pName, "vkGetInstanceProcAddr") == 0)
        return (PFN_vkVoidFunction)vkGetInstanceProcAddr;
    if (strcmp(pName, "vkGetDeviceProcAddr") == 0)
        return (PFN_vkVoidFunction)vkGetDeviceProcAddr;
    if (strcmp(pName, "vkCreateInstance") == 0)
        return (PFN_vkVoidFunction)play_fps_CreateInstance;
    if (strcmp(pName, "vkCreateDevice") == 0)
        return (PFN_vkVoidFunction)play_fps_CreateDevice;
    if (g_next_gipa)
        return g_next_gipa(instance, pName);
    return NULL;
}

VK_LAYER_EXPORT VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL
vkGetDeviceProcAddr(VkDevice device, const char *pName) {
    if (!pName)
        return NULL;
    if (strcmp(pName, "vkGetDeviceProcAddr") == 0)
        return (PFN_vkVoidFunction)vkGetDeviceProcAddr;
    if (strcmp(pName, "vkCreateDevice") == 0)
        return (PFN_vkVoidFunction)play_fps_CreateDevice;
    if (strcmp(pName, "vkQueuePresentKHR") == 0)
        return (PFN_vkVoidFunction)play_fps_PresentKHR;
    DevNode *n = NULL;
    if (device) {
        void *key = key_of(device);
        pthread_mutex_lock(&g_mutex);
        n = find_node(key);
        pthread_mutex_unlock(&g_mutex);
    }
    if (n && n->gdpa)
        return n->gdpa(device, pName);
    return NULL;
}
