#!/usr/bin/env python
import customtkinter as ctk
import subprocess
import threading
import webbrowser
from tkinter import messagebox
import re
import os
ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")
class RobloxManager(ctk.CTk):
	def __init__(self):
		super().__init__()
		if not self.check_prerequisites():
			self.quit()
			return
		self.title("Linux Roblox Account Manager")
		self.geometry("800x600")
		self.minsize(700,500)
		self.attributes("-topmost",True)
		header_frame=ctk.CTkFrame(self,fg_color="transparent",height=50)
		header_frame.pack(fill="x",padx=15,pady=(15,0))
		header_frame.pack_propagate(False)
		title_label=ctk.CTkLabel(header_frame,text="🎮 Roblox Instance Manager",font=ctk.CTkFont(size=24,weight="bold"))
		title_label.pack(side="left",padx=10)
		button_container=ctk.CTkFrame(header_frame,fg_color="transparent")
		button_container.pack(side="right",padx=10)
		refresh_btn=ctk.CTkButton(button_container,text="🔄 Refresh",width=100,command=self.refresh_instances)
		refresh_btn.pack(side="left",padx=5)
		self.tabview=ctk.CTkTabview(self)
		self.tabview.pack(fill="both",expand=True,padx=15,pady=(10,15))
		self.tabview.add("Instances")
		self.tabview.add("Actions")
		self.instances_frame=ctk.CTkScrollableFrame(self.tabview.tab("Instances"))
		self.instances_frame.pack(fill="both",expand=True,padx=5,pady=5)
		actions_frame=self.tabview.tab("Actions")
		actions_container=ctk.CTkFrame(actions_frame,fg_color="transparent")
		actions_container.pack(fill="both",expand=True,padx=20,pady=20)
		instance_label=ctk.CTkLabel(actions_container,text="Instance Management",font=ctk.CTkFont(size=18,weight="bold"))
		instance_label.pack(pady=(0,15))
		create_btn=ctk.CTkButton(actions_container,text="➕ Create New Instance",height=40,font=ctk.CTkFont(size=14),fg_color="#28a745",hover_color="#218838",command=self.create_instance_dialog)
		create_btn.pack(fill="x",pady=5)
		create_image_btn=ctk.CTkButton(actions_container,text="🖼️ Create from Custom Image",height=40,font=ctk.CTkFont(size=14),fg_color="#6f42c1",hover_color="#5a31a1",command=self.create_from_image_dialog)
		create_image_btn.pack(fill="x",pady=5)
		save_image_btn=ctk.CTkButton(actions_container,text="� Save Instance as Image",height=40,font=ctk.CTkFont(size=14),fg_color="#fd7e14",hover_color="#e66a00",command=self.save_image_dialog)
		save_image_btn.pack(fill="x",pady=5)
		bulk_label=ctk.CTkLabel(actions_container,text="Bulk Operations",font=ctk.CTkFont(size=18,weight="bold"))
		bulk_label.pack(pady=(25,15))
		stop_all_btn=ctk.CTkButton(actions_container,text="⏹️ Stop All Instances",height=40,font=ctk.CTkFont(size=14),fg_color="#ffc107",hover_color="#e0a800",command=self.stop_all_instances)
		stop_all_btn.pack(fill="x",pady=5)
		remove_all_btn=ctk.CTkButton(actions_container,text="🗑️ Remove All Instances",height=40,font=ctk.CTkFont(size=14),fg_color="#dc3545",hover_color="#c82333",command=self.remove_all_instances)
		remove_all_btn.pack(fill="x",pady=5)
		self.instances=[]
		self.refresh_instances()
		self.protocol("WM_DELETE_WINDOW",self._on_close)
	def check_prerequisites(self):
		try:
			result=subprocess.run("docker --version",shell=True,capture_output=True,text=True,timeout=5)
			if result.returncode!=0:
				messagebox.showerror("Docker Not Found","Docker is not installed or not running.\n\nPlease run the CLI version first:\n./run-instance.sh\n\nThe CLI will install Docker and build the required image.")
				return False
		except:
			messagebox.showerror("Docker Not Found","Docker is not installed or not running.\n\nPlease run the CLI version first:\n./run-instance.sh\n\nThe CLI will install Docker and build the required image.")
			return False
		try:
			result=subprocess.run("docker images --format '{{.Repository}}' | grep '^sober-multi$'",shell=True,capture_output=True,text=True,timeout=5)
			if result.returncode!=0 or not result.stdout.strip():
				messagebox.showerror("Base Image Not Found","The 'sober-multi' Docker image is not built.\n\nPlease run the CLI version first:\n./run-instance.sh\n\nThe CLI will automatically build the required image.")
				return False
		except:
			messagebox.showerror("Base Image Not Found","The 'sober-multi' Docker image is not built.\n\nPlease run the CLI version first:\n./run-instance.sh\n\nThe CLI will automatically build the required image.")
			return False
		return True
	def _on_close(self):
		self.destroy()
	def run_docker_command(self,cmd):
		try:
			result=subprocess.run(cmd,shell=True,capture_output=True,text=True,timeout=30)
			return result.stdout,result.stderr,result.returncode
		except subprocess.TimeoutExpired:
			return "","Command timeout",1
		except Exception as e:
			return "",str(e),1
	def refresh_instances(self):
		self.tabview.set("Instances")
		for widget in self.instances_frame.winfo_children():
			widget.destroy()
		self.instances=[]
		stdout,stderr,code=self.run_docker_command("docker ps -a --filter \"name=sober-instance-\" --format \"{{.Names}}|{{.Status}}|{{.Ports}}\"")
		if code!=0:
			error_label=ctk.CTkLabel(self.instances_frame,text=f"Error loading instances: {stderr}",text_color="#dc3545",font=ctk.CTkFont(size=14))
			error_label.pack(pady=20)
			return
		if not stdout.strip():
			no_instances_label=ctk.CTkLabel(self.instances_frame,text="No instances found.\nCreate one from the Actions tab!",font=ctk.CTkFont(size=16),text_color="gray")
			no_instances_label.pack(pady=50)
			return
		lines=stdout.strip().split("\n")
		for idx,line in enumerate(lines):
			parts=line.split("|")
			if len(parts)<2:
				continue
			name=parts[0]
			status=parts[1]
			instance_num=re.search(r'sober-instance-(\d+)',name)
			if not instance_num:
				continue
			instance_num=instance_num.group(1)
			port=6079+int(instance_num)
			is_running="Up" in status
			instance_frame=ctk.CTkFrame(self.instances_frame,fg_color=("#f0f0f0","#2b2b2b"))
			instance_frame.pack(fill="x",pady=8,padx=5)
			header_frame=ctk.CTkFrame(instance_frame,fg_color="transparent")
			header_frame.pack(fill="x",padx=15,pady=(15,10))
			status_color="#28a745" if is_running else "#6c757d"
			status_dot=ctk.CTkLabel(header_frame,text="●",text_color=status_color,font=ctk.CTkFont(size=24))
			status_dot.pack(side="left",padx=(0,10))
			info_container=ctk.CTkFrame(header_frame,fg_color="transparent")
			info_container.pack(side="left",fill="x",expand=True)
			name_label=ctk.CTkLabel(info_container,text=f"Instance {instance_num}",font=ctk.CTkFont(size=16,weight="bold"),anchor="w")
			name_label.pack(anchor="w")
			status_text="Running" if is_running else "Stopped"
			status_label=ctk.CTkLabel(info_container,text=f"Status: {status_text}",font=ctk.CTkFont(size=12),text_color="gray",anchor="w")
			status_label.pack(anchor="w")
			url_label=ctk.CTkLabel(info_container,text=f"http://localhost:{port}/vnc.html",font=ctk.CTkFont(size=11),text_color="#007bff",anchor="w")
			url_label.pack(anchor="w")
			button_frame=ctk.CTkFrame(instance_frame,fg_color="transparent")
			button_frame.pack(fill="x",padx=15,pady=(0,15))
			if is_running:
				open_btn=ctk.CTkButton(button_frame,text="🌐 Open Browser",width=120,fg_color="#007bff",hover_color="#0056b3",command=lambda p=port:self.open_browser(p))
				open_btn.pack(side="left",padx=3)
				stop_btn=ctk.CTkButton(button_frame,text="⏹️ Stop",width=100,fg_color="#ffc107",hover_color="#e0a800",command=lambda n=name:self.stop_instance(n))
				stop_btn.pack(side="left",padx=3)
			else:
				start_btn=ctk.CTkButton(button_frame,text="▶️ Start",width=100,fg_color="#28a745",hover_color="#218838",command=lambda n=name:self.start_instance(n))
				start_btn.pack(side="left",padx=3)
			remove_btn=ctk.CTkButton(button_frame,text="🗑️ Remove",width=100,fg_color="#dc3545",hover_color="#c82333",command=lambda n=name,num=instance_num:self.remove_instance(n,num))
			remove_btn.pack(side="left",padx=3)
			self.instances.append({"name":name,"status":status,"port":port,"running":is_running})
	def open_browser(self,port):
		webbrowser.open(f"http://localhost:{port}/vnc.html")
	def start_instance(self,name):
		def task():
			stdout,stderr,code=self.run_docker_command(f"docker start {name}")
			self.after(0,lambda: self._handle_start_result(code,stderr))
		threading.Thread(target=task,daemon=True).start()
	def _handle_start_result(self,code,stderr):
		if code==0:
			messagebox.showinfo("Success","Instance started successfully!")
			self.refresh_instances()
		else:
			messagebox.showerror("Error",f"Failed to start instance:\n{stderr}")
	def stop_instance(self,name):
		def task():
			stdout,stderr,code=self.run_docker_command(f"docker stop {name}")
			self.after(0,lambda: self._handle_stop_result(code,stderr))
		threading.Thread(target=task,daemon=True).start()
	def _handle_stop_result(self,code,stderr):
		if code==0:
			messagebox.showinfo("Success","Instance stopped successfully!")
			self.refresh_instances()
		else:
			messagebox.showerror("Error",f"Failed to stop instance:\n{stderr}")
	def remove_instance(self,name,instance_num):
		result=messagebox.askyesno("Confirm","Are you sure you want to remove this instance?")
		if result:
			def task():
				stdout,stderr,code=self.run_docker_command(f"docker rm -f {name}")
				self.after(0,lambda: self._handle_remove_result(code,stderr,instance_num))
			threading.Thread(target=task,daemon=True).start()
	def _handle_remove_result(self,code,stderr,instance_num):
		if code==0:
			messagebox.showinfo("Success",f"Instance {instance_num} removed successfully!")
			self.refresh_instances()
		else:
			messagebox.showerror("Error",f"Failed to remove instance:\n{stderr}")
	def create_instance_dialog(self):
		dialog=ctk.CTkInputDialog(text="Enter instance number:",title="Create Instance")
		instance_num=dialog.get_input()
		if instance_num and instance_num.isdigit():
			self.create_instance(instance_num,False)
		elif instance_num:
			messagebox.showerror("Error","Please enter a valid number")
	def create_from_image_dialog(self):
		stdout,stderr,code=self.run_docker_command("docker images --format '{{.Repository}}' | grep '^sober-multi-roblox$'")
		if code!=0 or not stdout.strip():
			messagebox.showerror("Error","Custom image 'sober-multi-roblox' not found!\nPlease create an image first using 'Save Instance as Image'.")
			return
		dialog=ctk.CTkInputDialog(text="Enter instance number:",title="Create from Image")
		instance_num=dialog.get_input()
		if instance_num and instance_num.isdigit():
			self.create_instance(instance_num,True)
		elif instance_num:
			messagebox.showerror("Error","Please enter a valid number")
	def create_instance(self,instance_num,from_image):
		def task():
			container_name=f"sober-instance-{instance_num}"
			stdout,stderr,code=self.run_docker_command(f"docker ps -a --format '{{{{.Names}}}}' | grep '^{container_name}$'")
			if stdout.strip():
				self.after(0,lambda: messagebox.showerror("Error",f"Instance {instance_num} already exists!"))
				return
			port=6079+int(instance_num)
			image_name="sober-multi-roblox" if from_image else "sober-multi"
			image_type="custom image" if from_image else "base image"
			log_dir=f"./sober-logs-{instance_num}"
			os.makedirs(log_dir,exist_ok=True)
			os.chmod(log_dir,0o777)
			cmd=f"docker run -d --name {container_name} --privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw -v ./sober-logs-{instance_num}:/root/.var/app/org.vinegarhq.Sober/data/sober/sober_logs -p {port}:6080 --device /dev/dri --device /dev/snd --cpus=\"1.0\" --memory=\"512m\" --memory-swap=\"3g\" --shm-size=\"512m\" {image_name}"
			stdout,stderr,code=self.run_docker_command(cmd)
			self.after(0,lambda: self._handle_create_result(code,stderr,instance_num,image_type,port))
		threading.Thread(target=task,daemon=True).start()
	def _handle_create_result(self,code,stderr,instance_num,image_type,port):
		if code==0:
			messagebox.showinfo("Success",f"Instance {instance_num} created from {image_type}!\n\nAccess at: http://localhost:{port}/vnc.html")
			self.refresh_instances()
		else:
			messagebox.showerror("Error",f"Failed to create instance:\n{stderr}")
	def save_image_dialog(self):
		dialog=ctk.CTkInputDialog(text="Enter instance number to save as image:",title="Save as Image")
		instance_num=dialog.get_input()
		if instance_num and instance_num.isdigit():
			self.save_image(instance_num)
		elif instance_num:
			messagebox.showerror("Error","Please enter a valid number")
	def save_image(self,instance_num):
		def task():
			container_name=f"sober-instance-{instance_num}"
			stdout,stderr,code=self.run_docker_command(f"docker ps -a --format '{{{{.Names}}}}' | grep '^{container_name}$'")
			if not stdout.strip():
				self.after(0,lambda: messagebox.showerror("Error",f"Instance {instance_num} does not exist!"))
				return
			image_name="sober-multi-roblox"
			stdout,stderr,code=self.run_docker_command(f"docker commit {container_name} {image_name}")
			self.after(0,lambda: self._handle_save_image_result(code,stderr,image_name))
		threading.Thread(target=task,daemon=True).start()
	def _handle_save_image_result(self,code,stderr,image_name):
		if code==0:
			messagebox.showinfo("Success",f"Image created successfully as '{image_name}'!\n\nYou can now create instances from this image.")
		else:
			messagebox.showerror("Error",f"Failed to create image:\n{stderr}")
	def stop_all_instances(self):
		result=messagebox.askyesno("Confirm","Are you sure you want to stop all instances?")
		if result:
			def task():
				stdout,stderr,code=self.run_docker_command("docker ps --filter \"name=sober-instance-\" --format \"{{.Names}}\" | xargs -r docker stop")
				self.after(0,lambda: self._handle_stop_all_result(code,stderr))
			threading.Thread(target=task,daemon=True).start()
	def _handle_stop_all_result(self,code,stderr):
		if code==0:
			messagebox.showinfo("Success","All instances stopped successfully!")
			self.refresh_instances()
		else:
			messagebox.showerror("Error",f"Failed to stop instances:\n{stderr}")
	def remove_all_instances(self):
		result=messagebox.askyesno("Confirm","Are you sure you want to remove ALL instances?\n\nThis action cannot be undone!")
		if result:
			def task():
				stdout,stderr,code=self.run_docker_command("docker ps -a --filter \"name=sober-instance-\" --format \"{{.Names}}\" | xargs -r docker rm -f")
				self.after(0,lambda: self._handle_remove_all_result(code,stderr))
			threading.Thread(target=task,daemon=True).start()
	def _handle_remove_all_result(self,code,stderr):
		if code==0:
			messagebox.showinfo("Success","All instances removed successfully!")
			self.refresh_instances()
		else:
			messagebox.showerror("Error",f"Failed to remove instances:\n{stderr}")
if __name__=="__main__":
	app=RobloxManager()
	app.mainloop()
