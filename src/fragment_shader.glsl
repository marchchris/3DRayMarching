#version 330 core

out vec4 FragColor;
uniform float time;
uniform vec2 windowSize;

mat3 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(
        oc * axis.x * axis.x + c,         oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c,         oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c
    );
}

float mandelbulb(vec3 p, mat3 rotation) {
    p = rotation * p;  // Apply rotation to the input point

    vec3 z = p;
    float dr = 1.0;
    float r = 0.0;
    float Power = ((time / 1000.0) * 0.1) + 1.0;  // Mandelbulb power

    for (int i = 0; i < 8; i++) {
        r = length(z);
        if (r > 2.0) break;

        // Convert to polar coordinates
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        dr =  pow(r, Power - 1.0) * Power * dr + 1.0;

        // Scale and rotate the point
        float zr = pow(r, Power);
        theta = theta * Power;
        phi = phi * Power;

        // Convert back to cartesian coordinates
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += p;
    }
    return 0.5 * log(r) * r / dr;
}


float distance_from_sphere(in vec3 p, in vec3 c, float r)
{
    return length(p - c) - r;
}

float map_the_world(in vec3 p)
{
    //float sphere_0 = distance_from_sphere(p, vec3(0.0), 1.0);
    vec3 rotationAxis = vec3(1.0, 1.0, 0.0);  // Rotate around the y-axis
    float rotationAngle = (time / 1000.0) * 0.1;  // Adjust the 0.1 scaling factor to control rotation speed
    mat3 rotation = rotationMatrix(rotationAxis, rotationAngle);

    float sphere_0 = mandelbulb(p, rotation);
    return sphere_0;
}

vec3 calculate_normal(in vec3 p)
{
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    float gradient_x = map_the_world(p + small_step.xyy) - map_the_world(p - small_step.xyy);
    float gradient_y = map_the_world(p + small_step.yxy) - map_the_world(p - small_step.yxy);
    float gradient_z = map_the_world(p + small_step.yyx) - map_the_world(p - small_step.yyx);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

vec3 ray_march(in vec3 ro, in vec3 rd)
{
    float total_distance_traveled = 0.0;
    const int NUMBER_OF_STEPS = 128;
    const float MINIMUM_HIT_DISTANCE = 0.001;
    const float MAXIMUM_TRACE_DISTANCE = 1000.0;

    int steps_taken = 0;

    for (int i = 0; i < NUMBER_OF_STEPS; ++i)
    {
        vec3 current_position = ro + total_distance_traveled * rd;

        float distance_to_closest = map_the_world(current_position);

        if (distance_to_closest < MINIMUM_HIT_DISTANCE) 
        {
            vec3 normal = calculate_normal(current_position);
            vec3 light_position = vec3(2.0, -5.0, 3.0);
            vec3 direction_to_light = normalize(current_position - light_position);

            float diffuse_intensity = max(0.0, dot(normal, direction_to_light));

            return vec3(float(steps_taken)/float(NUMBER_OF_STEPS), 0.0, 0.0) * diffuse_intensity;
        }

        if (total_distance_traveled > MAXIMUM_TRACE_DISTANCE)
        {   
            break;
        }
        total_distance_traveled += distance_to_closest;
        steps_taken += 1;
    }
    return vec3(float(steps_taken)/float(NUMBER_OF_STEPS), 0.0 ,0.0);
}


void main()
{
    vec2 uv = (gl_FragCoord.xy * 2. - windowSize) / windowSize.y;

    vec3 camera_position = vec3(0.0, 0.0, -2.0);
    vec3 ro = camera_position;
    vec3 rd = vec3(uv, 1.0);

    vec3 shaded_color = ray_march(ro, rd);

    FragColor = vec4(shaded_color, 1.0);
}
