
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include<iostream>
#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include <windows.h>


#define NThreads 512
#define NBlocks 1

#define Num NThreads*NBlocks




__device__ void swap(int &a, int &b){
	int t = a;
	a = b;
	b = t;
}

__global__ void bitonic_sort(int* arr){
	extern __shared__ int shared_arr[];
	const unsigned int tid = blockIdx.x * blockDim.x + threadIdx.x;
	//const unsigned int tid = threadIdx.x;
	shared_arr[tid] = arr[tid];
	__syncthreads();

	//for(int i=2; i<=blociDim.x; i<<=1){
	for(unsigned int i=2; i<=Num; i<<=1){
		for(unsigned int j=i>>1; j>0; j>>=1){
			unsigned int tid_comp = tid ^ j;
			if(tid_comp > tid){
				if((tid & i)==0){ //ascending
					if(shared_arr[tid]>shared_arr[tid_comp]){
						swap(shared_arr[tid],shared_arr[tid_comp]);
					}
				}
				else{ //desending
					if(shared_arr[tid]<shared_arr[tid_comp]){
						swap(shared_arr[tid],shared_arr[tid_comp]);
					}
				}
			}
			__syncthreads();
		}
	}
	arr[tid] = shared_arr[tid];
}


void swap(int s[],int i,int j)
{
	int temp;
	temp=s[i];
	s[i]=s[j];
	s[j]=temp;
}


void QuickSort(int s[],int low,int high)
{
	int i;
	int last;       
	if(low<high)    
	{
		last=low;   

		for(i=low+1;i<=high;i++)
		{
			if(s[i]<s[low])
				swap(s,++last,i);
		}

		swap(s,last,low);
		QuickSort(s,low,last-1); 
		QuickSort(s,last+1,high);
	}
}


int main(int argc, char* argv[])
{

	int* arr= (int*) malloc(Num*sizeof(int));
	int* arr1= (int*) malloc(Num*sizeof(int));
	//init array value
	time_t t;
	clock_t start1,end1;
	double usetime;


	srand((unsigned)time(&t));
	for(int i=0;i<Num;i++){
		arr[i] = rand() % 1000; 
	}

	//init device variable
	int* ptr;
	cudaMalloc((void**)&ptr,Num*sizeof(int));
	cudaMemcpy(ptr,arr,Num*sizeof(int),cudaMemcpyHostToDevice);

	for(int i=0;i<Num;i++){
		printf("%d\t",arr[i]);
	}


	printf("\n---------------- init ----------------\n");

	LARGE_INTEGER nFreq;
	 LARGE_INTEGER nBeginTime;

     LARGE_INTEGER nEndTime;
	 double utime;

	 QueryPerformanceFrequency(&nFreq);

     QueryPerformanceCounter(&nBeginTime); 

	start1 = clock();

	for(int i=0;i<Num;i++){
		arr1[i]=arr[i];

	}


	

		cudaEvent_t start, stop;
		float elapsedTime = 0.0;

		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		cudaEventRecord(start, 0);


		dim3 blocks(NBlocks,1);
		dim3 threads(NThreads,1);


		//bitonic_sort<<<blocks,threads,Num*sizeof(int)>>>(ptr);
		bitonic_sort<<<blocks,threads,Num*sizeof(int)>>>(ptr);

		//bitonic_sort<<<1,Num,Num*sizeof(int)>>>(ptr);


		cudaEventRecord(stop, 0);
		cudaEventSynchronize(stop);

		cudaEventElapsedTime(&elapsedTime, start, stop);

		cudaMemcpy(arr,ptr,Num*sizeof(int),cudaMemcpyDeviceToHost);

		printf("\n---------------- GPU£º ----------------\n");
		for(int i=0;i<Num;i++){
			printf("%d\t",arr[i]);
		}

		for(int i=0;i<Num-1;i++)
		for(int j=0;j<Num-1;j++){
			if(arr1[i]<arr1[j]){
				int t= arr1[i];
				arr1[i] = arr1[j];
				arr1[j] = t;
			}
		}

	 QueryPerformanceCounter(&nEndTime);

     utime=(double)(nEndTime.QuadPart-nBeginTime.QuadPart)/(double)nFreq.QuadPart;



		end1 =clock();

		printf("\n---------------- CPU£º ----------------\n");
		for(int i=0;i<Num-1;i++)
			printf("%d\t",arr1[i]);
		

		usetime = (double) (end1 - start1)*1000.0/CLK_TCK;


		printf("\n-------------- cpu: %f ms ----------------\n",utime);

		printf("\n-------------- gpu: %f ms-----------------\n\n",elapsedTime);


		cudaEventDestroy(start);
		cudaEventDestroy(stop);


		cudaFree(ptr);
		return 0;
}