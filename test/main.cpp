#include "imgui/imgui.h"
#include "imgui/imgui_impl_glfw.h"
#include "imgui/imgui_impl_opengl3.h"
#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>

int main()
{
  // Initialize GLFW
  if (!glfwInit())
  {
    // Handle initialization error
    std::cout << "Failed to initialize GLFW" << std::endl;
    return 1;
  }

  // Create a GLFW window
  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
  glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
  glfwSwapInterval(1);

  GLFWwindow* window = glfwCreateWindow(800, 600, "ImGui GLFW OpenGL3 Test", nullptr, nullptr);
  if (!window)
  {
    // Handle window creation error
    std::cout << "Failed to create GLFW window" << std::endl;
    glfwTerminate();
    return 1;
  }

  // Set the current context to the GLFW window
  glfwMakeContextCurrent(window);
  int status = gladLoadGLLoader(reinterpret_cast<GLADloadproc>(glfwGetProcAddress));
  if (!status)
  {
    // Handle GLAD initialization error
    std::cout << "Failed to initialize GLAD" << std::endl;
    glfwDestroyWindow(window);
    glfwTerminate();
    return 1;
  }

  // Initialize ImGui
  ImGui::CreateContext();
  if (! ImGui_ImplGlfw_InitForOpenGL(window, true)) {
    // Handle ImGui initialization error
    std::cout << "Failed to initialize ImGui for GLFW" << std::endl;
    return 1;
  }
  if (! ImGui_ImplOpenGL3_Init("#version 410")) {
    // Handle ImGui initialization error
    std::cout << "Failed to initialize ImGui for OpenGL3" << std::endl;
    return 1;
  }
  ImGuiIO& io = ImGui::GetIO();

  // Main loop
  while (!glfwWindowShouldClose(window))
  {
    // Process events
    glfwPollEvents();

    // Start ImGui frame
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();

    // ImGui code goes here
    ImGui::ShowDemoWindow();

    // Render ImGui
    ImGui::Render();

    // Clear the screen
    glClear(GL_COLOR_BUFFER_BIT);

    // Render ImGui draw data
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
    glFlush();

    // Swap buffers
    glfwSwapBuffers(window);
  }

  // Cleanup
  ImGui_ImplOpenGL3_Shutdown();
  ImGui::DestroyContext();
  glfwDestroyWindow(window);
  glfwTerminate();

  return 0;
}