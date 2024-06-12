#version 330 core
out vec4 FragColor;
void main()
{
    vec2 coord = gl_FragCoord.xy / vec2(800, 600); // Assuming window size is 800x600
    FragColor = vec4(coord.x, coord.y, 0.5, 1.0); // Color based on x, y coordinates
}
