#include <unistd.h>
#include <sys/types.h>
#include <pthread.h>
#include <semaphore.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define BUFFSIZE 10         

int buffer[BUFFSIZE];    //缓冲区数目

sem_t buffer_full; //可以使用的空缓冲区数（缓冲区中可以生产多少产品）
sem_t buffer_empty;  //缓冲区内可以使用的产品数（可以消费的产品数）
pthread_mutex_t thread_mutex;  //互斥信号量

pthread_t produce_thread;
pthread_t consume_thread;

void *consume()
{
    int k = 0;
    while (k < 100)
    {
        sem_wait(&buffer_empty);
        pthread_mutex_lock(&thread_mutex);
        //遍历缓冲区，看有哪些缓冲区是可以生产产品的
        int first_product = -1;
        int i;
        for (i = 0; i < BUFFSIZE; i++)
        {
            printf("%02d ", i);
            if (buffer[i] == 0)
                printf("%s", "null");
            else {
                printf("%d", buffer[i]);
                if (first_product == -1) {
                    printf("\t<--consume");
                    first_product = i;
                }
            }

            printf("\n");
        }
        printf("consume product %02d\n", first_product);
        buffer[first_product] = 0;
        pthread_mutex_unlock(&thread_mutex);
        sem_post(&buffer_full);
        k++;
    }
    sleep(2);
    return NULL;
}

void *produce()
{
    int j = 0;
    while (j < 100)
    {
        sem_wait(&buffer_full);
        pthread_mutex_lock(&thread_mutex);
        int first_null = -1;
        int i;
        for (i = 0; i < BUFFSIZE; i++)
        {
            printf("%02d ", i);
            if (buffer[i] == 0) {
                printf("%s", "null");
                if (first_null == -1) {
                    printf("\t<--produce");
                    first_null = i;
                }
            }
            else
                printf("%d", buffer[i]);

            printf("\n");
        }
        printf("produce product %02d\n",first_null);
        buffer[first_null] = 1;
        pthread_mutex_unlock(&thread_mutex);
        sem_post(&buffer_empty);
        j++;
    }
    sleep(5);
    return NULL;
}

int main(void)
{
    int index;
    for (index = 0; index < BUFFSIZE; index++)
        buffer[index] = 0;

    sem_init(&buffer_full, 0, BUFFSIZE);
    sem_init(&buffer_empty, 0, 0);
    pthread_mutex_init(&thread_mutex, NULL);

    pthread_create(&consume_thread, NULL, consume, NULL);
    pthread_create(&produce_thread, NULL, produce, NULL);
    pthread_join(consume_thread, NULL);
    pthread_join(produce_thread, NULL);

    return 0;
}
